import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';

class MenuModifiersDialog extends StatefulWidget {
  final MenuItem item;

  const MenuModifiersDialog({super.key, required this.item});

  @override
  State<MenuModifiersDialog> createState() => _MenuModifiersDialogState();
}

class _MenuModifiersDialogState extends State<MenuModifiersDialog> {
  Map<String, dynamic> _attributes = {};
  
  // Variations
  List<dynamic> _variations = [];
  int _selectedVariationIndex = 0;

  // Modifiers
  List<dynamic> _modifierGroups = [];
  // groupIndex -> Set of selected modifier indices
  Map<int, Set<int>> _selectedModifiers = {};

  @override
  void initState() {
    super.initState();
    _parseAttributes();
  }

  void _parseAttributes() {
    try {
      if (widget.item.attributesJson != null && widget.item.attributesJson!.isNotEmpty) {
        _attributes = jsonDecode(widget.item.attributesJson!);
        
        if (_attributes['variations'] != null) {
          _variations = _attributes['variations'] as List<dynamic>;
        }
        
        if (_attributes['modifier_groups'] != null) {
          _modifierGroups = _attributes['modifier_groups'] as List<dynamic>;
          for (int i = 0; i < _modifierGroups.length; i++) {
            _selectedModifiers[i] = {};
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing attributes: $e");
    }
  }

  double _calculateAdditionalPrice() {
    double additional = 0.0;
    
    // Variation price difference (variation price - base price)
    if (_variations.isNotEmpty) {
      final basePrice = widget.item.price;
      final varPrice = (_variations[_selectedVariationIndex]['price'] as num).toDouble();
      additional += (varPrice - basePrice);
    }

    // Modifiers price
    for (int g = 0; g < _modifierGroups.length; g++) {
      final mods = _modifierGroups[g]['modifiers'] as List<dynamic>;
      for (int mIndex in _selectedModifiers[g]!) {
        additional += (mods[mIndex]['price'] as num).toDouble();
      }
    }

    return additional;
  }

  String _generateSelectedJson() {
    final Map<String, dynamic> selected = {};
    
    if (_variations.isNotEmpty) {
      selected['variation'] = _variations[_selectedVariationIndex]['name'];
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

  void _onConfirm() {
    // Validate required groups
    for (int g = 0; g < _modifierGroups.length; g++) {
      final group = _modifierGroups[g];
      final isRequired = group['required'] == true;
      if (isRequired && _selectedModifiers[g]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пожалуйста, выберите опции для: ${group['name']}')),
        );
        return;
      }
    }

    Navigator.of(context).pop({
      'json': _generateSelectedJson(),
      'price': _calculateAdditionalPrice(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final additionalPrice = _calculateAdditionalPrice();
    final totalPrice = widget.item.price + additionalPrice;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item.cleanName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const Divider(height: 32),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Variations
                    if (_variations.isNotEmpty) ...[
                      const Text(
                        'Размер / Вариация',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_variations.length, (index) {
                          final v = _variations[index];
                          final isSelected = index == _selectedVariationIndex;
                          return ChoiceChip(
                            label: Text('${v['name']} (${(v['price'] as num).toCurrency(context)}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedVariationIndex = index;
                                });
                              }
                            },
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).primaryColor : null,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Modifier Groups
                    for (int g = 0; g < _modifierGroups.length; g++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _modifierGroups[g]['name'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (_modifierGroups[g]['required'] == true)
                            const Text('Обязательно', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate((_modifierGroups[g]['modifiers'] as List).length, (mIndex) {
                        final mod = _modifierGroups[g]['modifiers'][mIndex];
                        final isSelected = _selectedModifiers[g]!.contains(mIndex);
                        return CheckboxListTile(
                          title: Text(mod['name']),
                          subtitle: Text('+${(mod['price'] as num).toCurrency(context)}'),
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
                        );
                      }),
                      const SizedBox(height: 24),
                    ]
                  ],
                ),
              ),
            ),
            
            // Footer
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Итого: ${totalPrice.toCurrency(context)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Добавить', style: TextStyle(fontSize: 16)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
