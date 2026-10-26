// ==============================================================================
// Title: CatalogBrowserActions
// Path: frontend/lib/features/menu/view/widgets/catalog/catalog_browser_actions.dart
// Description: Фильтрация, сортировка и массовые операции каталога меню.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/merge_items_dialog.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';

// [ИНВАРИАНТ] Сервис массовых действий и фильтрации браузера каталога
class CatalogBrowserActions {
  const CatalogBrowserActions._();

  static List<dynamic> filterCategories({
    required CategoryState catState,
    required String categoryType,
    required bool showArchived,
    required String searchQuery,
    required int? currentCategoryId,
  }) {
    if (catState is! CategoryLoaded) return [];

    return catState.categories.where((c) {
      if (!showArchived && c.isArchived) return false;
      if (categoryType == 'all' && c.categoryType == 'ingredient') return false;
      if (categoryType != 'all' && c.categoryType != categoryType) return false;
      if (searchQuery.isNotEmpty) {
        return c.name.toLowerCase().contains(searchQuery);
      }
      return c.parentId == currentCategoryId;
    }).toList()
      ..sort((a, b) {
        final sortA = a.sortOrder == 0 ? 999999 : a.sortOrder;
        final sortB = b.sortOrder == 0 ? 999999 : b.sortOrder;
        final cmp = sortA.compareTo(sortB);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
  }

  static List<dynamic> filterItems({
    required MenuState menuState,
    required bool showArchived,
    required String searchQuery,
    required int? currentCategoryId,
    required bool Function(MenuItem) itemFilter,
  }) {
    if (menuState is! MenuLoaded) return [];

    final currentCatStr = currentCategoryId?.toString();
    return menuState.items.where((i) {
      if (!showArchived && !i.isAvailable) return false;
      if (!itemFilter(i)) return false;
      if (i.parentId != null) return false;

      if (searchQuery.isNotEmpty) {
        final name = i.cleanName.toLowerCase();
        final barcode = i.barcode?.toLowerCase() ?? '';
        return name.contains(searchQuery) || barcode.contains(searchQuery);
      }

      final iCatStr = i.categoryId.toString();
      final isRootItem = iCatStr == '0' || iCatStr == 'null' || iCatStr == 'uncategorized' || iCatStr == '';
      return iCatStr == currentCatStr || (isRootItem && currentCatStr == null);
    }).toList()
      ..sort((a, b) {
        final sortA = a.sortOrder == 0 ? 999999 : a.sortOrder;
        final sortB = b.sortOrder == 0 ? 999999 : b.sortOrder;
        final cmp = sortA.compareTo(sortB);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
  }

  static void toggleVisibilitySelected({
    required BuildContext context,
    required Set<int> selectedCategories,
    required Set<int> selectedItems,
    required List<dynamic> currentCategories,
    required List<dynamic> currentItems,
  }) {
    final selectedCats = currentCategories.where((c) => selectedCategories.contains(c.id)).toList();
    final selectedDishes = currentItems.where((i) => selectedItems.contains(i.id)).toList();
    if (selectedCats.isEmpty && selectedDishes.isEmpty) return;

    final anyVisible = selectedCats.any((c) => c.isVisible == true) || selectedDishes.any((i) => i.isAvailable == true);
    final targetVisible = !anyVisible;

    for (final cat in selectedCats) {
      context.read<CategoryBloc>().add(UpdateCategory(id: cat.id, isVisible: targetVisible));
    }
    for (final item in selectedDishes) {
      context.read<MenuBloc>().add(UpdateMenuItem(item.id, {'is_available': targetVisible}));
    }
    context.read<CategoryBloc>().add(const LoadCategories());

    final count = selectedCats.length + selectedDishes.length;
    AppToast.showSuccess(
      context,
      targetVisible ? 'Элементы отображаются на кассе' : 'Элементы скрыты на кассе',
      subtitle: '$count шт.',
    );
  }

  static void restoreSelected({
    required BuildContext context,
    required Set<int> selectedCategories,
    required Set<int> selectedItems,
    required List<dynamic> currentCategories,
    required List<dynamic> currentItems,
    required VoidCallback onCleared,
  }) {
    final selectedCats = currentCategories.where((c) => selectedCategories.contains(c.id)).toList();
    final selectedDishes = currentItems.where((i) => selectedItems.contains(i.id)).toList();
    if (selectedCats.isEmpty && selectedDishes.isEmpty) return;

    for (final cat in selectedCats) {
      context.read<CategoryBloc>().add(RestoreCategory(cat.id));
    }
    for (final item in selectedDishes) {
      context.read<MenuBloc>().add(UpdateMenuItem(item.id, {'is_available': true}));
    }
    context.read<CategoryBloc>().add(const LoadCategories());

    final count = selectedCats.length + selectedDishes.length;
    onCleared();

    AppToast.showSuccess(
      context,
      'Восстановлено элементов',
      subtitle: '$count шт.',
    );
  }

  static void mergeSelected({
    required BuildContext context,
    required Set<int> selectedItems,
    required List<dynamic> currentItems,
    required VoidCallback onMerged,
  }) {
    final itemsToMerge = currentItems
        .whereType<MenuItem>()
        .where((i) => selectedItems.contains(i.id))
        .toList();
    if (itemsToMerge.length < 2) return;

    showMergeItemsDialog(
      context: context,
      items: itemsToMerge,
      onMerged: onMerged,
    );
  }
}
