import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/core/widgets/icon_picker_field.dart';

void showAddRetailProductDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.cleanName ?? '');
  
  final sellingPriceController = TextEditingController(text: isEditing ? itemToEdit.price.toInt().toString() : '');
  String selectedUnit = 'pcs';
  String? selectedIcon;
  final currency = context.read<SettingsBloc>().state.currency;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Редактировать товар' : 'Новый товар для витрины'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название товара (Сникерс, Кола)'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sellingPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Цена продажи на кассе ($currency)'),
                  ),
                  const SizedBox(height: 16),
                  IconPickerField(
                    selectedIcon: selectedIcon,
                    onIconSelected: (icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final sPrice = double.tryParse(sellingPriceController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty && sPrice > 0) {
                    final Map<String, dynamic> attributes = {};
                    if (selectedIcon != null) {
                      attributes['icon'] = 'icon:$selectedIcon';
                    }
                    if (isEditing) {
                      final Map<String, dynamic> data = {
                        'name': nameController.text,
                        'price': sPrice,
                      };
                      if (attributes.isNotEmpty) data['attributes'] = attributes;
                      context.read<MenuBloc>().add(UpdateRetailProduct(itemToEdit.id, data));
                    } else {
                      context.read<MenuBloc>().add(
                            CreateRetailProduct(
                              name: nameController.text,
                              categoryId: currentCategoryId ?? 0,
                              unit: selectedUnit,
                              purchasePrice: 0.0,
                              sellingPrice: sPrice,
                              attributes: attributes.isNotEmpty ? attributes : null,
                            ),
                          );
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text(isEditing ? 'Сохранить' : 'Создать'),
              ),
            ],
          );
        },
      );
    },
  );
}
