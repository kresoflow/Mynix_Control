import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_event.dart';

void showAddCategoryDialog(BuildContext context, {int? currentCategoryId, dynamic itemToEdit, String type = 'dish'}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.name ?? '');
  final sortOrderController = TextEditingController(text: isEditing ? itemToEdit.sortOrder.toString() : '');
  bool isVisible = itemToEdit?.isVisible ?? true;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Редактировать категорию' : 'Новая категория'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Название категории'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Порядок сортировки'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Отображать на кассе'),
                  value: isVisible,
                  onChanged: (val) {
                    setState(() {
                      isVisible = val;
                    });
                  },
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
                  final sortOrder = int.tryParse(sortOrderController.text) ?? 0;
                  if (nameController.text.isNotEmpty) {
                    if (isEditing) {
                      context.read<CategoryBloc>().add(
                            UpdateCategory(
                              id: itemToEdit.id,
                              name: nameController.text,
                              sortOrder: sortOrder,
                              isVisible: isVisible,
                            ),
                          );
                    } else {
                      context.read<CategoryBloc>().add(
                            CreateCategory(
                              name: nameController.text,
                              categoryType: type,
                              parentId: currentCategoryId,
                              sortOrder: sortOrder,
                              isVisible: isVisible,
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
