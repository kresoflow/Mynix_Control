// ==============================================================================
// МОДУЛЬ: Склад / Валидатор дубликатов массового ввода
// ДОМЕН: lib/features/inventory/view/widgets/bulk_add/bulk_add_duplicate_validator.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'dish_row.dart';
import 'retail_row.dart';
import 'ingredient_row.dart';
import 'category_row.dart';

// ─── 1. Сервис проверки коллизий в строках массового ввода ───────────────────

/// Валидатор коллизий дубликатов для таблицы пакетного добавления номенклатуры.
class BulkAddDuplicateValidator {
  static String? checkDuplicate({
    required BuildContext context,
    required int tabIndex,
    required int index,
    required List<DishRowData> dishRows,
    required List<RetailRowData> retailRows,
    required List<IngredientRowData> ingredientRows,
    required List<CategoryRowData> categoryRows,
    String? categoryType,
  }) {
    if (tabIndex == 0 && index < dishRows.length) {
      return _checkDish(context, index, dishRows);
    } else if (tabIndex == 1 && index < retailRows.length) {
      return _checkRetail(context, index, retailRows);
    } else if (tabIndex == 2 && index < ingredientRows.length) {
      return _checkIngredient(context, index, ingredientRows);
    } else if (tabIndex == 3 && index < categoryRows.length) {
      return _checkCategory(context, index, categoryRows, categoryType: categoryType);
    }
    return null;
  }

  static String? _checkDish(BuildContext context, int index, List<DishRowData> dishRows) {
    final name = dishRows[index].nameController.text.trim().toLowerCase();
    if (name.length < 2) return null;
    final otherBatch = dishRows.asMap().entries.any((e) => e.key != index && e.value.nameController.text.trim().toLowerCase() == name);
    if (otherBatch) return 'Дубликат названия в строках массового ввода';

    final menuState = context.read<MenuBloc>().state;
    if (menuState is MenuLoaded) {
      final match = DuplicateDetector.findMenuItemDuplicate(
        items: menuState.items,
        queryName: dishRows[index].nameController.text.trim(),
        isRetail: false,
        currentCategoryId: dishRows[index].categoryId,
      );
      if (match != null) return match.matchReason;
    }
    return null;
  }

  static String? _checkRetail(BuildContext context, int index, List<RetailRowData> retailRows) {
    final r = retailRows[index];
    final name = r.nameController.text.trim().toLowerCase();
    final flavor = r.flavorController.text.trim().toLowerCase();
    final volume = r.volumeController.text.trim().toLowerCase();
    final barcode = r.barcodeController.text.trim();
    if (name.length < 2 && barcode.isEmpty) return null;

    if (name.length >= 2) {
      final composite = '$name|$flavor|$volume';
      final otherBatch = retailRows.asMap().entries.any((e) {
        if (e.key == index) return false;
        final item = e.value;
        return '${item.nameController.text.trim().toLowerCase()}|${item.flavorController.text.trim().toLowerCase()}|${item.volumeController.text.trim().toLowerCase()}' == composite;
      });
      if (otherBatch) return 'Дубликат товара и вкуса в строках ввода';
    }

    if (barcode.isNotEmpty) {
      final otherBatchBc = retailRows.asMap().entries.any((e) => e.key != index && e.value.barcodeController.text.trim() == barcode);
      if (otherBatchBc) return 'Дубликат штрихкода в строках массового ввода';
    }

    final menuState = context.read<MenuBloc>().state;
    if (menuState is MenuLoaded) {
      final match = DuplicateDetector.findMenuItemDuplicate(
        items: menuState.items,
        queryName: r.nameController.text.trim(),
        isRetail: true,
        queryFlavor: r.flavorController.text.trim().isNotEmpty ? r.flavorController.text.trim() : null,
        queryVolume: r.volumeController.text.trim().isNotEmpty ? r.volumeController.text.trim() : null,
        queryBarcode: barcode.isNotEmpty ? barcode : null,
        currentCategoryId: r.categoryId,
      );
      if (match != null) return match.matchReason;
    }
    return null;
  }

  static String? _checkIngredient(BuildContext context, int index, List<IngredientRowData> ingredientRows) {
    final r = ingredientRows[index];
    final name = r.nameController.text.trim().toLowerCase();
    final barcode = r.sku?.trim() ?? '';
    if (name.length < 2 && barcode.isEmpty) return null;

    if (name.length >= 2) {
      final otherBatch = ingredientRows.asMap().entries.any((e) => e.key != index && e.value.nameController.text.trim().toLowerCase() == name);
      if (otherBatch) return 'Дубликат сырья в строках массового ввода';
    }

    if (barcode.isNotEmpty) {
      final otherBatchBc = ingredientRows.asMap().entries.any((e) => e.key != index && (e.value.sku?.trim() ?? '') == barcode);
      if (otherBatchBc) return 'Дубликат SKU/штрихкода в строках ввода';
    }

    final ingState = context.read<IngredientBloc>().state;
    if (ingState is IngredientLoaded) {
      final match = DuplicateDetector.findIngredientDuplicate(
        ingredients: ingState.ingredients,
        queryName: r.nameController.text.trim(),
        queryBarcode: barcode.isNotEmpty ? barcode : null,
        currentCategoryId: r.categoryId,
      );
      if (match != null) return match.matchReason;
    }
    return null;
  }

  static String? _checkCategory(BuildContext context, int index, List<CategoryRowData> categoryRows, {String? categoryType}) {
    final r = categoryRows[index];
    final name = r.nameController.text.trim().toLowerCase();
    if (name.length < 2) return null;
    final otherBatch = categoryRows.asMap().entries.any((e) => e.key != index && e.value.nameController.text.trim().toLowerCase() == name);
    if (otherBatch) return 'Дубликат категории в строках массового ввода';

    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      final match = DuplicateDetector.findCategoryDuplicate(
        categories: catState.categories,
        queryName: r.nameController.text.trim(),
        categoryType: categoryType,
      );
      if (match != null) return match.matchReason;
    }
    return null;
  }
}
