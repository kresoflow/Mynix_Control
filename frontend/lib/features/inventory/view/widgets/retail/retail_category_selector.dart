import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RetailCategorySelector extends StatelessWidget {
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;

  const RetailCategorySelector({
    super.key,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  void _showCreateCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                context.read<CategoryBloc>().add(
                  CreateCategory(name: nameCtrl.text.trim()),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Категория добавляется...')),
                );
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedCategoryId,
                  items: state.categories.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: onCategoryChanged,
                  validator: (v) => v == null ? 'Выберите категорию' : null,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.plusSquare,
                    size: 40,
                    color: AppColors.brandPrimary,
                  ),
                  onPressed: () => _showCreateCategoryDialog(context),
                  tooltip: 'Новая категория',
                ),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
