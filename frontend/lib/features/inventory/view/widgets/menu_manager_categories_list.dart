import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_event.dart';
import 'package:retail_os_frontend/features/pos/models/menu_category.dart';

class MenuManagerCategoriesList extends StatelessWidget {
  final int? currentParentId;
  final Function(MenuCategory) onNavigate;
  final Function(int) onDelete;

  const MenuManagerCategoriesList({
    super.key,
    required this.currentParentId,
    required this.onNavigate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CategoryLoaded) {
          final subCategories = state.categories
              .where((c) => c.parentId == currentParentId)
              .toList();

          if (subCategories.isEmpty) {
            return const Center(
              child: Text('Нет подкатегорий. Создайте новую папку.'),
            );
          }

          return ListView.builder(
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final cat = subCategories[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => onNavigate(cat),
                  leading: const Icon(
                    Icons.folder,
                    color: Colors.amber,
                    size: 36,
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: cat.isVisible,
                        onChanged: (val) {
                          context.read<CategoryBloc>().add(
                            UpdateCategory(id: cat.id, isVisible: val),
                          );
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onDelete(cat.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
