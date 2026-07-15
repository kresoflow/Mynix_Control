import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

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

  bool _hasModifiers = false;
  
  // Variations
  final List<Map<String, dynamic>> _variations = [];
  
  // Modifiers
  final List<Map<String, dynamic>> _modifierGroups = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.cleanName ?? '');
    _priceController = TextEditingController(text: widget.existingItem?.price.toString() ?? '');
    
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
        'modifiers': []
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

      if (widget.existingItem != null) {
         context.read<MenuBloc>().add(UpdateMenuItem(
             widget.existingItem!.id,
             {
                'name': name,
                'price': price,
                'attributes': attributes,
             }
         ));
      } else {
         context.read<MenuBloc>().add(
            CreateMenuItem(
               name: name,
               category: categoryId,
               price: price,
               attributes: attributes,
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
                  Text(widget.existingItem != null ? 'Редактировать блюдо' : 'Добавить блюдо', style: Theme.of(context).textTheme.headlineSmall),
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
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                        // Variations
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Вариации (Размеры)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: _addVariation,
                              icon: const Icon(PhosphorIconsRegular.plus),
                              label: const Text('Добавить размер'),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._variations.asMap().entries.map((e) {
                          final i = e.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: _variations[i]['name'],
                                    decoration: const InputDecoration(labelText: 'Название (напр. Стандарт)', isDense: true, border: OutlineInputBorder()),
                                    onChanged: (v) => _variations[i]['name'] = v,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: _variations[i]['price'].toString(),
                                    decoration: const InputDecoration(labelText: 'Цена', isDense: true, border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => _variations[i]['price'] = double.tryParse(v) ?? 0,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                                  onPressed: () => setState(() => _variations.removeAt(i)),
                                )
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),
                        // Modifiers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Группы модификаторов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: _addModifierGroup,
                              icon: const Icon(PhosphorIconsRegular.plus),
                              label: const Text('Добавить группу'),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._modifierGroups.asMap().entries.map((e) {
                          final gIndex = e.key;
                          final group = e.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: group['name'],
                                          decoration: const InputDecoration(labelText: 'Название группы (напр. Соусы)', isDense: true, border: OutlineInputBorder()),
                                          onChanged: (v) => group['name'] = v,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                                        onPressed: () => setState(() => _modifierGroups.removeAt(gIndex)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CheckboxListTile(
                                          title: const Text('Обязательно к выбору', style: TextStyle(fontSize: 14)),
                                          value: group['required'] ?? false,
                                          onChanged: (v) => setState(() => group['required'] = v),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: (group['max_selections'] ?? 1).toString(),
                                          decoration: const InputDecoration(labelText: 'Макс. кол-во опций', isDense: true, border: OutlineInputBorder()),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => group['max_selections'] = int.tryParse(v) ?? 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Опции:', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  ...(group['modifiers'] as List).asMap().entries.map((me) {
                                    final mIndex = me.key;
                                    final mod = me.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0, left: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              initialValue: mod['name'],
                                              decoration: const InputDecoration(labelText: 'Опция', isDense: true, border: OutlineInputBorder()),
                                              onChanged: (v) => mod['name'] = v,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: TextFormField(
                                              initialValue: mod['price'].toString(),
                                              decoration: const InputDecoration(labelText: 'Цена', isDense: true, border: OutlineInputBorder()),
                                              keyboardType: TextInputType.number,
                                              onChanged: (v) => mod['price'] = double.tryParse(v) ?? 0,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(PhosphorIconsRegular.x, size: 18),
                                            onPressed: () => setState(() => (group['modifiers'] as List).removeAt(mIndex)),
                                          )
                                        ],
                                      ),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: () => setState(() => (group['modifiers'] as List).add({'name': '', 'price': 0})),
                                    icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                                    label: const Text('Добавить опцию'),
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      ]
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена', style: TextStyle(fontSize: 16))),
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
