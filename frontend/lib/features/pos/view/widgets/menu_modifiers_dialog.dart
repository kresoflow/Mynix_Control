import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'modifiers/mini_cart_item.dart';
import 'modifiers/dialog_variations_list.dart';
import 'modifiers/dialog_modifier_groups_list.dart';
import 'modifiers/dialog_mini_cart_view.dart';

export 'modifiers/mini_cart_item.dart';

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
  List<dynamic> _variations = [];
  List<dynamic> _modifierGroups = [];
  final Map<int, Set<int>> _selectedModifiers = {};
  final List<MiniCartItem> _miniCart = [];

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
          'name': child.cleanName,
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
          _modifierGroups = groups.where((g) => !(widget.item.isRetail && g['name'] == 'Вкус')).toList();
          for (int i = 0; i < _modifierGroups.length; i++) {
            _selectedModifiers[i] = {};
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing attributes: $e');
    }
  }

  double _calculateModifiersPrice() {
    double additional = 0.0;
    for (int g = 0; g < _modifierGroups.length; g++) {
      final mods = _modifierGroups[g]['modifiers'] as List<dynamic>;
      for (int mIndex in (_selectedModifiers[g] ?? {})) {
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
      for (int mIndex in (_selectedModifiers[g] ?? {})) {
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
    for (int g = 0; g < _modifierGroups.length; g++) {
      final group = _modifierGroups[g];
      if (group['required'] == true && (_selectedModifiers[g] ?? {}).isEmpty) {
        AppToast.showWarning(
          context,
          'Выберите опции',
          subtitle: 'Для группы: ${group['name']}',
        );
        return;
      }
    }

    final jsonStr = _generateSelectedJson(variationIndex);
    final price = _calculateAdditionalPrice(variationIndex);
    final existingIndex = _miniCart.indexWhere((item) => item.jsonStr == jsonStr);

    if (existingIndex >= 0) {
      setState(() => _miniCart[existingIndex].quantity++);
    } else {
      final String vName = variationIndex != null ? _variations[variationIndex]['name'] : widget.item.name;
      final List<String> mNames = [];
      for (int g = 0; g < _modifierGroups.length; g++) {
        final mods = _modifierGroups[g]['modifiers'] as List;
        for (int mIndex in (_selectedModifiers[g] ?? {})) {
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
      final totalAdded = _miniCart.fold(0, (sum, i) => sum + i.quantity);
      for (var item in _miniCart) {
        for (int i = 0; i < item.quantity; i++) {
          widget.onAdd!({'json': item.jsonStr, 'price': item.price});
        }
      }
      AppToast.showCart(
        context,
        widget.item.cleanName,
        count: totalAdded,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MynixDialog(
      title: widget.item.cleanName,
      icon: PhosphorIconsRegular.hamburger,
      width: 850,
      content: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            final leftContent = SingleChildScrollView(
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DialogVariationsList(
                    variations: _variations,
                    basePrice: widget.item.price,
                    additionalModifiersPrice: _calculateModifiersPrice(),
                    onSelectVariation: _addToMiniCart,
                  ),
                  if (_variations.isEmpty) ...[
                    AppGhostButton(
                      label: 'Добавить в корзину • ${(widget.item.price + _calculateModifiersPrice()).toCurrency(context)}',
                      onPressed: () => _addToMiniCart(null),
                      icon: PhosphorIconsRegular.plusCircle,
                    ),
                    const SizedBox(height: 24),
                  ],
                  DialogModifierGroupsList(
                    modifierGroups: _modifierGroups,
                    selectedModifiers: _selectedModifiers,
                    onToggleModifier: (g, mIndex, isSelected) {
                      setState(() {
                        if (isSelected) {
                          final maxSel = _modifierGroups[g]['max_selections'] ?? 99;
                          if ((_selectedModifiers[g] ?? {}).length < maxSel) {
                            _selectedModifiers[g]?.add(mIndex);
                          }
                        } else {
                          _selectedModifiers[g]?.remove(mIndex);
                        }
                      });
                    },
                  ),
                ],
              ),
            );

            final rightContent = DialogMiniCartView(
              miniCart: _miniCart,
              baseItemPrice: widget.item.price,
              isMobile: isMobile,
              isReadOnly: widget.isReadOnly,
              hasVariations: _variations.isNotEmpty,
              onClearCart: () => setState(() => _miniCart.clear()),
              onIncrementQuantity: (i) => setState(() => _miniCart[i].quantity++),
              onDecrementQuantity: (i) {
                setState(() {
                  if (_miniCart[i].quantity > 1) {
                    _miniCart[i].quantity--;
                  } else {
                    _miniCart.removeAt(i);
                  }
                });
              },
              onRemoveItem: (i) => setState(() => _miniCart.removeAt(i)),
              onSubmitCart: _submitCart,
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: leftContent),
                  Container(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                  ),
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                    child: rightContent,
                  ),
                ],
              );
            }

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
          },
        ),
      ),
      actions: const [],
    );
  }
}
