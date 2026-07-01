import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_event.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';

import 'catalog_enums.dart';
import 'catalog_item_widgets.dart';
import 'catalog_dialogs.dart';

class CatalogListView extends StatelessWidget {
  final List<dynamic> currentCategories;
  final List<dynamic> currentItems;
  final int? currentCategoryId;
  final CategoryManageMode manageMode;
  final Set<int> selectedCategories;
  final Set<int> selectedItems;
  final Function(int) onToggleCategorySelection;
  final Function(int) onToggleItemSelection;
  final Function(dynamic) onNavigateToCategory;

  const CatalogListView({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: totalItems,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index < currentCategories.length) {
                final cat = currentCategories[index];
                return CategoryListItem(
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
                return MenuListItem(
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
          ),
        ),
      ),
    );
  }
}
