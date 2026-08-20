import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'modifiers/mini_cart_item.dart';
import 'modifiers/modifiers_calculator.dart';
import 'modifiers/dialog_modifiers_body.dart';

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

    final jsonStr = ModifiersCalculator.generateSelectedJson(
      variations: _variations,
      modifierGroups: _modifierGroups,
      selectedModifiers: _selectedModifiers,
      variationIndex: variationIndex,
    );
    final price = ModifiersCalculator.calculateAdditionalPrice(
      item: widget.item,
      variations: _variations,
      modifierGroups: _modifierGroups,
      selectedModifiers: _selectedModifiers,
      variationIndex: variationIndex,
    );
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
    return MynixDialog(
      title: widget.item.cleanName,
      icon: PhosphorIconsRegular.hamburger,
      width: 850,
      content: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        child: DialogModifiersBody(
          item: widget.item,
          variations: _variations,
          modifierGroups: _modifierGroups,
          selectedModifiers: _selectedModifiers,
          miniCart: _miniCart,
          isReadOnly: widget.isReadOnly,
          additionalModifiersPrice: ModifiersCalculator.calculateModifiersPrice(
            modifierGroups: _modifierGroups,
            selectedModifiers: _selectedModifiers,
          ),
          onSelectVariation: _addToMiniCart,
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
        ),
      ),
      actions: const [],
    );
  }
}
