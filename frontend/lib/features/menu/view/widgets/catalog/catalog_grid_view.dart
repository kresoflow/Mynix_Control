import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_event.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';

import 'catalog_enums.dart';
import 'catalog_item_widgets.dart';
import 'catalog_dialogs.dart';

class CatalogGridView extends StatelessWidget {
  final List<dynamic> currentCategories;
  final List<dynamic> currentItems;
  final int? currentCategoryId;
  final CategoryManageMode manageMode;
  final Set<int> selectedCategories;
  final Set<int> selectedItems;
  final Function(int) onToggleCategorySelection;
  final Function(int) onToggleItemSelection;
  final Function(dynamic) onNavigateToCategory;

  const CatalogGridView({
    super.key,
    required this.currentCategories,
    required this.currentItems,
    this.currentCategoryId,
    required this.manageMode,
    required this.selectedCategories,
    required this.selectedItems,
    required this.onToggleCategorySelection,
    required this.onToggleItemSelection,
    required this.onNavigateToCategory,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = currentCategories.length + currentItems.length;
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < currentCategories.length) {
          final cat = currentCategories[index];
          return CategoryGridItem(
            category: cat,
            manageMode: manageMode,
            isSelected: selectedCategories.contains(cat.id),
            onTap: () {
              if (manageMode == CategoryManageMode.delete) {
                onToggleCategorySelection(cat.id);
              } else if (manageMode == CategoryManageMode.none) {
                onNavigateToCategory(cat);
              }
            },
            onToggleSelect: (val) => onToggleCategorySelection(cat.id),
            onVisibilityToggle: () => context.read<CategoryBloc>().add(UpdateCategory(id: cat.id, isVisible: !cat.isVisible)),
            onEdit: () => showAddCategoryDialog(context, currentCategoryId: currentCategoryId, itemToEdit: cat),
            onDelete: () => context.read<CategoryBloc>().add(DeleteCategory(cat.id, mode: 'all')),
          );
        } else {
          final item = currentItems[index - currentCategories.length];
          return MenuGridItem(
            item: item,
            manageMode: manageMode,
            isSelected: selectedItems.contains(item.id),
            onTap: () {
              if (manageMode == CategoryManageMode.delete) {
                onToggleItemSelection(item.id);
              }
            },
            onToggleSelect: (val) => onToggleItemSelection(item.id),
            onEdit: () => showAddMenuItemDialog(context, itemToEdit: item),
            onDelete: () => context.read<MenuBloc>().add(DeleteMenuItem(item.id)),
          );
        }
      },
    );
  }
}
