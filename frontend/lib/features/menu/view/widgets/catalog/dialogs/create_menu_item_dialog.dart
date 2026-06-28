import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/settings/bloc/settings_bloc.dart';

void showAddMenuItemDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.cleanName ?? '');
  final priceController = TextEditingController(text: itemToEdit?.price.toInt().toString() ?? '');
  
  int? selectedCategoryId = currentCategoryId;
  final currency = context.read<SettingsBloc>().state.currency;
  if (isEditing && itemToEdit?.categoryId != null) {
    selectedCategoryId = int.tryParse(itemToEdit!.categoryId);
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Редактировать блюдо' : 'Новое блюдо'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название блюда'),
                    autofocus: !isEditing,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Цена ($currency)'),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, catState) {
                      if (catState is CategoryLoaded) {
                        final dishCategories = catState.categories.where((c) => c.categoryType == 'dish').toList();
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Категория'),
                          value: selectedCategoryId,
                          items: [
                            const DropdownMenuItem<int>(value: null, child: Text('Без категории')),
                            ...dishCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              selectedCategoryId = val;
                            });
                          },
                        );
                      }
                      return const SizedBox.shrink();
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
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty && price > 0) {
                    if (isEditing) {
                      context.read<MenuBloc>().add(
                            UpdateMenuItem(
                              itemToEdit.id,
                              {
                                'name': nameController.text,
                                'price': price,
                                'category_id': selectedCategoryId,
                              },
                            ),
                          );
                    } else {
                      context.read<MenuBloc>().add(
                            CreateMenuItem(
                              name: nameController.text,
                              price: price,
                              category: selectedCategoryId?.toString() ?? '',
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
        }
      );
    },
  );
}
