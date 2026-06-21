import 'package:flutter/material.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';
import 'catalog_enums.dart';
import 'catalog_item_widgets.dart';

class CatalogContentView extends StatelessWidget {
  final List<dynamic> currentCategories;
  final List<dynamic> currentItems;
  final CategoryViewMode viewMode;
  final CategoryManageMode manageMode;
  final Set<int> selectedCategories;
  final Set<int> selectedItems;
  final void Function(dynamic category) onCategoryTap;
  final void Function(dynamic category, bool? val) onCategoryToggle;
  final void Function(dynamic category) onCategoryVisibilityToggle;
  final void Function(dynamic category) onCategoryEdit;
  final void Function(dynamic category) onCategoryDelete;
  final void Function(MenuItem item) onItemTap;
  final void Function(MenuItem item, bool? val) onItemToggle;
  final void Function(MenuItem item) onItemEdit;
  final void Function(MenuItem item) onItemDelete;
  final String emptyMessage;

  const CatalogContentView({
    super.key,
    required this.currentCategories,
    required this.currentItems,
    required this.viewMode,
    required this.manageMode,
    required this.selectedCategories,
    required this.selectedItems,
    required this.onCategoryTap,
    required this.onCategoryToggle,
    required this.onCategoryVisibilityToggle,
    required this.onCategoryEdit,
    required this.onCategoryDelete,
    required this.onItemTap,
    required this.onItemToggle,
    required this.onItemEdit,
    required this.onItemDelete,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (currentCategories.isEmpty && currentItems.isEmpty) return Center(child: Text(emptyMessage));

    final totalItems = currentCategories.length + currentItems.length;

    if (viewMode == CategoryViewMode.list) {
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
                    onTap: () => onCategoryTap(cat),
                    onToggleSelect: (val) => onCategoryToggle(cat, val),
                    onVisibilityToggle: () => onCategoryVisibilityToggle(cat),
                    onEdit: () => onCategoryEdit(cat),
                    onDelete: () => onCategoryDelete(cat),
                  );
                } else {
                  final item = currentItems[index - currentCategories.length];
                  return MenuListItem(
                    item: item,
                    manageMode: manageMode,
                    isSelected: selectedItems.contains(item.id),
                    onTap: () => onItemTap(item),
                    onToggleSelect: (val) => onItemToggle(item, val),
                    onEdit: () => onItemEdit(item),
                    onDelete: () => onItemDelete(item),
                  );
                }
              },
            ),
          ),
        ),
      );
    }

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
            onTap: () => onCategoryTap(cat),
            onToggleSelect: (val) => onCategoryToggle(cat, val),
            onVisibilityToggle: () => onCategoryVisibilityToggle(cat),
            onEdit: () => onCategoryEdit(cat),
            onDelete: () => onCategoryDelete(cat),
          );
        } else {
          final item = currentItems[index - currentCategories.length];
          return MenuGridItem(
            item: item,
            manageMode: manageMode,
            isSelected: selectedItems.contains(item.id),
            onTap: () => onItemTap(item),
            onToggleSelect: (val) => onItemToggle(item, val),
            onEdit: () => onItemEdit(item),
            onDelete: () => onItemDelete(item),
          );
        }
      },
    );
  }
}
