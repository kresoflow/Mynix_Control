import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';

void showAddMenuItemDialog(BuildContext context, {int? currentCategoryId, MenuItem? itemToEdit}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.cleanName ?? '');
  final priceController = TextEditingController(text: itemToEdit?.price.toInt().toString() ?? '');

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(isEditing ? 'Редактировать блюдо' : 'Новое блюдо'),
        content: Column(
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
              decoration: const InputDecoration(labelText: 'Цена (₽)'),
            ),
          ],
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
                          },
                        ),
                      );
                } else {
                  context.read<MenuBloc>().add(
                        CreateMenuItem(
                          name: nameController.text,
                          price: price,
                          category: currentCategoryId?.toString() ?? '',
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
}
