import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MiniCartItem {
  final String variationName;
  final List<String> modifierNames;
  final String jsonStr;
  final double price;
  int quantity;

  MiniCartItem({
    required this.variationName,
    required this.modifierNames,
    required this.jsonStr,
    required this.price,
    this.quantity = 1,
  });
}

class MenuModifiersDialog extends StatefulWidget {
  final MenuItem item;
  final List<MenuItem>? childrenItems;
  final bool isReadOnly;
  final Function(Map<String, dynamic>)? onAdd;

  const MenuModifiersDialog({
    super.key, 
    required this.item, 
    this.childrenItems,
    this.isReadOnly = false,
    this.onAdd,
  });

  @override
  State<MenuModifiersDialog> createState() => _MenuModifiersDialogState();
}

class _MenuModifiersDialogState extends State<MenuModifiersDialog> {
  Map<String, dynamic> _attributes = {};
  
  // Variations
  List<dynamic> _variations = [];
  
  // Modifiers
  List<dynamic> _modifierGroups = [];
  Map<int, Set<int>> _selectedModifiers = {};

  // Mini Cart
  List<MiniCartItem> _miniCart = [];

  @override
  void initState() {
    super.initState();
    _parseAttributes();
  }

  void _parseAttributes() {
    try {
      if (widget.childrenItems != null && widget.childrenItems!.isNotEmpty) {
        _variations = widget.childrenItems!.map((child) => {
          'id': child.id,
          'name': child.name.split('|TYPE|')[0],
          'price': child.price,
          'barcode': child.barcode,
          'retail_product_id': child.attributesJson != null ? jsonDecode(child.attributesJson!)['retail_product_id'] : null,
        }).toList();
      }

      if (widget.item.attributesJson != null && widget.item.attributesJson!.isNotEmpty) {
        _attributes = jsonDecode(widget.item.attributesJson!);
        
        if (_variations.isEmpty && _attributes['variations'] != null) {
          _variations = _attributes['variations'] as List<dynamic>;
        }
        
        if (_attributes['modifier_groups'] != null) {
          final groups = _attributes['modifier_groups'] as List<dynamic>;
          // Ignore the 'Вкус' modifier group for retail items since it's a fixed property of the parent product
          _modifierGroups = groups.where((g) => !(widget.item.isRetail && g['name'] == 'Вкус')).toList();
          
          for (int i = 0; i < _modifierGroups.length; i++) {
            _selectedModifiers[i] = {};
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing attributes: $e");
    }
  }

  double _calculateModifiersPrice() {
    double additional = 0.0;
    for (int g = 0; g < _modifierGroups.length; g++) {
      final mods = _modifierGroups[g]['modifiers'] as List<dynamic>;
      for (int mIndex in _selectedModifiers[g]!) {
        additional += (mods[mIndex]['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return additional;
  }

  double _calculateAdditionalPrice(int? variationIndex) {
    double additional = _calculateModifiersPrice();
    if (variationIndex != null && _variations.isNotEmpty) {
      final basePrice = widget.item.price;
      final varPrice = (_variations[variationIndex]['price'] as num?)?.toDouble() ?? 0.0;
      additional += (varPrice - basePrice);
    }
    return additional;
  }

  String _generateSelectedJson(int? variationIndex) {
    final Map<String, dynamic> selected = {};
    
    if (variationIndex != null && _variations.isNotEmpty) {
      selected['variation'] = _variations[variationIndex]['name'];
      if (_variations[variationIndex]['id'] != null) {
        selected['child_item_id'] = _variations[variationIndex]['id'];
      }
    }
    
    final List<Map<String, dynamic>> modsList = [];
    for (int g = 0; g < _modifierGroups.length; g++) {
      final group = _modifierGroups[g];
      final mods = group['modifiers'] as List<dynamic>;
      for (int mIndex in _selectedModifiers[g]!) {
        modsList.add({
          'group': group['name'],
          'name': mods[mIndex]['name'],
          'price': mods[mIndex]['price'],
        });
      }
    }
    
    if (modsList.isNotEmpty) {
      selected['modifiers'] = modsList;
    }
    
    return jsonEncode(selected);
  }

  void _addToMiniCart(int? variationIndex) {
    if (widget.isReadOnly) return;

    // Validate required groups
    for (int g = 0; g < _modifierGroups.length; g++) {
      final group = _modifierGroups[g];
      if (group['required'] == true && _selectedModifiers[g]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Выберите опции для: ${group['name']}'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final jsonStr = _generateSelectedJson(variationIndex);
    final price = _calculateAdditionalPrice(variationIndex);

    final existingIndex = _miniCart.indexWhere((item) => item.jsonStr == jsonStr);
    if (existingIndex >= 0) {
      setState(() {
        _miniCart[existingIndex].quantity++;
      });
    } else {
      String vName = variationIndex != null ? _variations[variationIndex]['name'] : widget.item.name;
      List<String> mNames = [];
      for (int g = 0; g < _modifierGroups.length; g++) {
        final mods = _modifierGroups[g]['modifiers'] as List;
        for (int mIndex in _selectedModifiers[g]!) {
          mNames.add(mods[mIndex]['name']);
        }
      }

      setState(() {
        _miniCart.add(MiniCartItem(
          variationName: vName,
          modifierNames: mNames,
          jsonStr: jsonStr,
          price: price,
        ));
      });
    }
  }

  void _submitCart() {
    if (widget.onAdd != null) {
      for (var item in _miniCart) {
        for (int i = 0; i < item.quantity; i++) {
          widget.onAdd!({
            'json': item.jsonStr,
            'price': item.price,
          });
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Добавлено в заказ: ${_miniCart.fold(0, (sum, i) => sum + i.quantity)} поз.'),
          backgroundColor: AppColors.brandPrimary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.width < 768 ? 100 : 24,
            left: 16,
            right: 16,
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int totalItems = _miniCart.fold(0, (sum, item) => sum + item.quantity);
    double totalCartPrice = _miniCart.fold(0.0, (sum, item) => sum + ((widget.item.price + item.price) * item.quantity));

    return MynixDialog(
      title: widget.item.cleanName,
      icon: PhosphorIconsRegular.hamburger,
      width: 850, // Made slightly wider for better desktop/tablet view
      content: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            
            Widget leftContent = SingleChildScrollView(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Variations at the top
                    if (_variations.isNotEmpty) ...[
                      Text(
                        'Вариации (кликните для добавления)',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(_variations.length, (index) {
                          final v = _variations[index];
                          final varPrice = (v['price'] as num?)?.toDouble() ?? 0.0;
                          final finalPrice = varPrice + _calculateModifiersPrice();
                          final isLast = index == _variations.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                            child: InkWell(
                              onTap: () => _addToMiniCart(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        v['name'],
                                        style: AppTextStyles.body.copyWith(
                                          color: isDark ? AppColors.darkText : AppColors.lightText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      finalPrice.toCurrency(context),
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.brandPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(PhosphorIconsRegular.plusCircle, color: AppColors.brandPrimary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // If no variations, show a button to add configuration at the top
                    if (_variations.isEmpty) ...[
                      AppGhostButton(
                        label: 'Добавить в корзину • ${(widget.item.price + _calculateModifiersPrice()).toCurrency(context)}',
                        onPressed: () => _addToMiniCart(null),
                        icon: PhosphorIconsRegular.plusCircle,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Modifiers
                    if (_modifierGroups.isNotEmpty)
                      ...List.generate(_modifierGroups.length, (g) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _modifierGroups[g]['name'],
                                    style: AppTextStyles.h3.copyWith(
                                      color: isDark ? AppColors.darkText : AppColors.lightText,
                                    ),
                                  ),
                                  if (_modifierGroups[g]['required'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Обязательно',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                                child: Column(
                                  children: List.generate((_modifierGroups[g]['modifiers'] as List).length, (mIndex) {
                                    final mod = _modifierGroups[g]['modifiers'][mIndex];
                                    final isSelected = _selectedModifiers[g]!.contains(mIndex);
                                    final isLast = mIndex == (_modifierGroups[g]['modifiers'] as List).length - 1;
                                    
                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          activeColor: AppColors.brandPrimary,
                                          checkColor: Colors.black,
                                          title: Text(
                                            mod['name'],
                                            style: AppTextStyles.body.copyWith(
                                              color: isDark ? AppColors.darkText : AppColors.lightText,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          subtitle: Text(
                                            mod['price'] != null && mod['price'] != 0 ? '+${(mod['price'] as num?)?.toDouble().toCurrency(context) ?? '0'}' : '',
                                            style: AppTextStyles.caption.copyWith(
                                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                            ),
                                          ),
                                          value: isSelected,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                final maxSel = _modifierGroups[g]['max_selections'] ?? 99;
                                                if (_selectedModifiers[g]!.length < maxSel) {
                                                  _selectedModifiers[g]!.add(mIndex);
                                                }
                                              } else {
                                                _selectedModifiers[g]!.remove(mIndex);
                                              }
                                            });
                                          },
                                        ),
                                        if (!isLast)
                                          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
            );

            Widget rightContent = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsRegular.shoppingBag, 
                           color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Мини-корзина',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const Spacer(),
                      if (totalItems > 0)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _miniCart.clear();
                            });
                          },
                          icon: Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
                          label: Text(
                            'Очистить всё',
                            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _miniCart.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIconsRegular.shoppingCart, 
                                     size: 48, 
                                     color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext).withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  _variations.isNotEmpty 
                                      ? 'Выберите опции слева и кликните на нужную вариацию'
                                      : 'Соберите конфигурацию и нажмите "Добавить в корзину"',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _miniCart.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _miniCart[index];
                              final itemPrice = widget.item.price + item.price;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.brandPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.variationName,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.darkText : AppColors.lightText,
                                            ),
                                          ),
                                          if (item.modifierNames.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              item.modifierNames.join(', '),
                                              style: AppTextStyles.caption.copyWith(
                                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            itemPrice.toCurrency(context),
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.brandPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quantity controls
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(PhosphorIconsRegular.minusCircle, size: 22),
                                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              if (item.quantity > 1) {
                                                item.quantity--;
                                              } else {
                                                _miniCart.removeAt(index);
                                              }
                                            });
                                          },
                                        ),
                                        Container(
                                          width: 24,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${item.quantity}',
                                            style: AppTextStyles.body.copyWith(
                                              color: isDark ? AppColors.darkText : AppColors.lightText,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(PhosphorIconsRegular.plusCircle, size: 22),
                                          color: AppColors.brandPrimary,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              item.quantity++;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(PhosphorIconsRegular.trash, size: 20),
                                          color: AppColors.danger,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _miniCart.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  if (!widget.isReadOnly) ...[
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      label: totalItems > 0 
                          ? 'В чек (${totalCartPrice.toCurrency(context)})' 
                          : 'Выберите опции',
                      onPressed: totalItems > 0 ? _submitCart : null,
                      icon: PhosphorIconsRegular.checkCircle,
                    ),
                  ],
                ],
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: leftContent),
                  Container(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  Expanded(flex: 4, child: rightContent),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: leftContent),
                  Container(
                    width: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(flex: 4, child: rightContent),
                ],
              );
            }
          },
        ),
      ),
      actions: const [],
    );
  }
}
