import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';

import 'menu_manager_categories_list.dart';
import 'menu_manager_items_grid.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/menu_manager_breadcrumbs.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


class MenuManagerTab extends StatefulWidget {
  const MenuManagerTab({super.key});

  @override
  State<MenuManagerTab> createState() => _MenuManagerTabState();
}

class _MenuManagerTabState extends State<MenuManagerTab> {
  // Navigation state (null means root)
  List<MenuCategory> _navigationHistory = [];

  int? get _currentParentId =>
      _navigationHistory.isEmpty ? null : _navigationHistory.last.id;

  void _navigateToCategory(MenuCategory category) {
    setState(() {
      _navigationHistory.add(category);
    });
  }

  void _navigateUpTo(int index) {
    setState(() {
      _navigationHistory = _navigationHistory.sublist(0, index + 1);
    });
  }

  void _navigateRoot() {
    setState(() {
      _navigationHistory.clear();
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sortOrderController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Новая папка (Категория)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название категории',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sortOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Порядок сортировки',
                ),
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
                  context.read<CategoryBloc>().add(
                    CreateCategory(
                      name: nameController.text,
                      sortOrder: sortOrder,
                      parentId: _currentParentId,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMenuItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    if (_currentParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Товары можно создавать только внутри категорий! Перейдите в нужную папку.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Новый товар (Блюдо)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название товара'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Цена (с)'),
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
                  context.read<MenuBloc>().add(
                    CreateMenuItem(
                      name: nameController.text,
                      price: price,
                      category: _currentParentId.toString(),
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(BuildContext context, int id) {
    context.read<CategoryBloc>().add(DeleteCategory(id));
  }

  void _deleteMenuItem(BuildContext context, int id) {
    context.read<MenuBloc>().add(DeleteMenuItem(id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuManagerBreadcrumbs(
              navigationHistory: _navigationHistory,
              onNavigateRoot: _navigateRoot,
              onNavigateUpTo: _navigateUpTo,
              onAddCategory: () => _showAddCategoryDialog(context),
              onAddMenuItem: _currentParentId == null
                  ? null
                  : () => _showAddMenuItemDialog(context),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: MenuManagerCategoriesList(
                      currentParentId: _currentParentId,
                      onNavigate: _navigateToCategory,
                      onDelete: (id) => _deleteCategory(context, id),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: MenuManagerItemsGrid(
                      currentParentId: _currentParentId,
                      onDelete: (id) => _deleteMenuItem(context, id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
