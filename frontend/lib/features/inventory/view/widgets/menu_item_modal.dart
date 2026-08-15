import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'menu_item/menu_item_variations_section.dart';
import 'menu_item/menu_item_modifier_groups_section.dart';

class MenuItemModal extends StatefulWidget {
  final int? preselectedCategoryId;
  final MenuItem? existingItem;

  const MenuItemModal({super.key, this.preselectedCategoryId, this.existingItem});

  @override
  State<MenuItemModal> createState() => _MenuItemModalState();
}

class _MenuItemModalState extends State<MenuItemModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _barcodeController;

  bool _hasModifiers = false;
  final List<Map<String, dynamic>> _variations = [];
  final List<Map<String, dynamic>> _modifierGroups = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.cleanName ?? '');
    _priceController = TextEditingController(text: widget.existingItem?.price.toString() ?? '');
    _barcodeController = TextEditingController(text: widget.existingItem?.barcode ?? '');

    if (widget.existingItem?.attributesJson != null && widget.existingItem!.attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(widget.existingItem!.attributesJson!);
        if (attrs.containsKey('variations')) {
          for (var v in attrs['variations']) {
            _variations.add(Map<String, dynamic>.from(v));
          }
        }
        if (attrs.containsKey('modifier_groups')) {
          for (var mg in attrs['modifier_groups']) {
            _modifierGroups.add(Map<String, dynamic>.from(mg));
          }
        }
        if (_variations.isNotEmpty || _modifierGroups.isNotEmpty) {
          _hasModifiers = true;
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _addVariation() {
    setState(() {
      _variations.add({'name': '', 'price': 0});
    });
  }

  void _addModifierGroup() {
    setState(() {
      _modifierGroups.add({
        'name': '',
        'required': false,
        'max_selections': 1,
        'modifiers': [],
      });
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate() && (widget.preselectedCategoryId != null || widget.existingItem != null)) {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final categoryId = widget.existingItem?.categoryId.toString() ?? widget.preselectedCategoryId.toString();

      Map<String, dynamic>? attributes;

      if (_hasModifiers) {
        attributes = {};
        if (_variations.isNotEmpty) {
          attributes['variations'] = _variations;
        }
        if (_modifierGroups.isNotEmpty) {
          attributes['modifier_groups'] = _modifierGroups;
        }
      }

      final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();

      if (widget.existingItem != null) {
        context.read<MenuBloc>().add(UpdateMenuItem(
          widget.existingItem!.id,
          {
            'name': name,
            'price': price,
            'attributes': attributes,
            'barcode': barcode,
          },
        ));
      } else {
        context.read<MenuBloc>().add(
          CreateMenuItem(
            name: name,
            category: categoryId,
            price: price,
            attributes: attributes,
            barcode: barcode,
          ),
        );
      }

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingItem != null ? 'Редактировать блюдо' : 'Добавить блюдо',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Название блюда', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'Обязательное поле' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'Базовая цена', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Штрихкод (опционально)',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: SwitchListTile(
                          title: const Text('Блюдо имеет размеры или модификаторы (опции)', style: TextStyle(fontWeight: FontWeight.bold)),
                          value: _hasModifiers,
                          onChanged: (val) => setState(() => _hasModifiers = val),
                          activeColor: AppColors.brandPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (_hasModifiers) ...[
                        const SizedBox(height: 32),
                        MenuItemVariationsSection(
                          variations: _variations,
                          onAddVariation: _addVariation,
                          onRemoveVariation: (i) => setState(() => _variations.removeAt(i)),
                        ),
                        const SizedBox(height: 24),
                        MenuItemModifierGroupsSection(
                          modifierGroups: _modifierGroups,
                          onAddGroup: _addModifierGroup,
                          onRemoveGroup: (gIndex) => setState(() => _modifierGroups.removeAt(gIndex)),
                          onAddOption: (gIndex) => setState(() => (_modifierGroups[gIndex]['modifiers'] as List).add({'name': '', 'price': 0})),
                          onRemoveOption: (gIndex, mIndex) => setState(() => (_modifierGroups[gIndex]['modifiers'] as List).removeAt(mIndex)),
                          onToggleRequired: (gIndex, val) => setState(() => _modifierGroups[gIndex]['required'] = val),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
