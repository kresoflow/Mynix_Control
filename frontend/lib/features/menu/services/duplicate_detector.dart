import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class DuplicateMatch<T> {
  final T item;
  final String matchReason;
  final bool isSameCategory;
  final String? categoryName;

  const DuplicateMatch({
    required this.item,
    required this.matchReason,
    this.isSameCategory = true,
    this.categoryName,
  });
}

class DuplicateDetector {
  static DuplicateMatch<MenuItem>? findMenuItemDuplicate({
    required List<MenuItem> items,
    required String queryName,
    String? queryBarcode,
    int? currentCategoryId,
    int? excludeItemId,
  }) {
    final cleanQuery = _normalize(queryName);
    final cleanBarcode = queryBarcode?.trim();

    if (cleanQuery.length < 2 && (cleanBarcode == null || cleanBarcode.isEmpty)) {
      return null;
    }

    for (final item in items) {
      if (excludeItemId != null && item.id == excludeItemId) continue;

      if (cleanBarcode != null && cleanBarcode.isNotEmpty && item.barcode != null && item.barcode!.trim() == cleanBarcode) {
        return DuplicateMatch(
          item: item,
          matchReason: 'Штрихкод совпадает с «${item.cleanName}»',
          isSameCategory: currentCategoryId == null || item.categoryId == currentCategoryId.toString(),
          categoryName: item.categoryName,
        );
      }

      final itemClean = _normalize(item.cleanName);
      if (cleanQuery.isNotEmpty && itemClean == cleanQuery) {
        return DuplicateMatch(
          item: item,
          matchReason: 'Позиция «${item.cleanName}» уже существует',
          isSameCategory: currentCategoryId == null || item.categoryId == currentCategoryId.toString(),
          categoryName: item.categoryName,
        );
      }
    }

    return null;
  }

  static DuplicateMatch<Ingredient>? findIngredientDuplicate({
    required List<Ingredient> ingredients,
    required String queryName,
    String? queryBarcode,
    int? currentCategoryId,
    int? excludeIngredientId,
  }) {
    final cleanQuery = _normalize(queryName);
    final cleanBarcode = queryBarcode?.trim();

    if (cleanQuery.length < 2 && (cleanBarcode == null || cleanBarcode.isEmpty)) {
      return null;
    }

    for (final ing in ingredients) {
      if (excludeIngredientId != null && ing.id == excludeIngredientId) continue;

      if (cleanBarcode != null && cleanBarcode.isNotEmpty && ing.barcode != null && ing.barcode!.trim() == cleanBarcode) {
        return DuplicateMatch(
          item: ing,
          matchReason: 'Штрихкод совпадает с «${ing.name}»',
          isSameCategory: currentCategoryId == null || ing.categoryId == currentCategoryId,
          categoryName: null,
        );
      }

      final ingClean = _normalize(ing.name);
      if (cleanQuery.isNotEmpty && ingClean == cleanQuery) {
        return DuplicateMatch(
          item: ing,
          matchReason: 'Сырье «${ing.name}» уже существует',
          isSameCategory: currentCategoryId == null || ing.categoryId == currentCategoryId,
          categoryName: null,
        );
      }
    }

    return null;
  }

  static DuplicateMatch<MenuCategory>? findCategoryDuplicate({
    required List<MenuCategory> categories,
    required String queryName,
    String? categoryType,
    int? excludeCategoryId,
  }) {
    final cleanQuery = _normalize(queryName);
    if (cleanQuery.length < 2) return null;

    for (final cat in categories) {
      if (excludeCategoryId != null && cat.id == excludeCategoryId) continue;
      if (categoryType != null && cat.categoryType != categoryType) continue;

      final catClean = _normalize(cat.name);
      if (catClean == cleanQuery) {
        return DuplicateMatch(
          item: cat,
          matchReason: 'Категория «${cat.name}» уже существует',
          isSameCategory: true,
          categoryName: null,
        );
      }
    }

    return null;
  }

  static String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
