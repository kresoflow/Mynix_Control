import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_event.dart';

class AddCategoryDialog extends StatelessWidget {
  const AddCategoryDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddCategoryDialog());
  }

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    return AlertDialog(
      title: const Text('Новая категория'),
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(
          labelText: 'Название',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isNotEmpty) {
              context.read<CategoryBloc>().add(
                CreateCategory(name: nameCtrl.text.trim()),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Категория добавляется...')),
              );
            }
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
