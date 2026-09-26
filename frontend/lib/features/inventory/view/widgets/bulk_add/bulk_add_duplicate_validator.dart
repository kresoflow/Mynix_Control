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
  }) {
    if (tabIndex == 0 && index < dishRows.length) {
      return _checkDish(context, index, dishRows);
    } else if (tabIndex == 1 && index < retailRows.length) {
      return _checkRetail(context, index, retailRows);
    } else if (tabIndex == 2 && index < ingredientRows.length) {
      return _checkIngredient(context, index, ingredientRows);
    } else if (tabIndex == 3 && index < categoryRows.length) {
      return _checkCategory(context, index, categoryRows);
    }
    return null;
  }

  static String? _checkDish(BuildContext context, int index, List<DishRowData> dishRows) {
    final name = dishRows[index].nameController.text.trim().toLowerCase();
    if (name.length < 2) return null;
    final otherBatch = dishRows.asMap().entries.any((e) => e.key != index && e.value.nameController.text.trim().toLowerCase() == name);
    if (otherBatch) return 'Дубликат названия в строках массового ввода';
    final menuState = context.read<MenuBloc>().state;
    if (menuState is MenuLoaded && menuState.items.where((i) => !i.isRetail && i.isAvailable).any((i) => i.cleanName.trim().toLowerCase() == name)) {
      return 'Блюдо «$name» уже есть в меню';
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

      final menuState = context.read<MenuBloc>().state;
      if (menuState is MenuLoaded) {
        final normVol = DuplicateDetector.normalizeVolume(volume);
        final exists = menuState.items.where((i) => i.isRetail && i.isAvailable).any((i) {
          if (i.cleanName.trim().toLowerCase() != name || (i.flavorString ?? '').trim().toLowerCase() != flavor) return false;
          if (normVol.isNotEmpty) {
            if (i.variations != null && i.variations!.isNotEmpty) {
              return i.variations!.any((v) => DuplicateDetector.normalizeVolume(v['name']?.toString() ?? '') == normVol);
            }
            return DuplicateDetector.normalizeVolume(i.variationsSummary ?? '') == normVol;
          }
          return (i.variations == null || i.variations!.isEmpty) && (i.variationsSummary == null || i.variationsSummary!.isEmpty);
        });
        if (exists) {
          final desc = [r.nameController.text.trim(), if (flavor.isNotEmpty) r.flavorController.text.trim(), if (volume.isNotEmpty) r.volumeController.text.trim()].join(' ');
          return 'Товар «$desc» уже есть на витрине';
        }
      }
    }

    if (barcode.isNotEmpty) {
      final otherBatchBc = retailRows.asMap().entries.any((e) => e.key != index && e.value.barcodeController.text.trim() == barcode);
      if (otherBatchBc) return 'Дубликат штрихкода в строках массового ввода';
      final menuState = context.read<MenuBloc>().state;
      if (menuState is MenuLoaded && menuState.items.where((i) => i.isAvailable).any((i) => i.barcode != null && i.barcode!.trim() == barcode)) {
        return 'Штрихкод $barcode уже используется в каталоге';
      }
    }
    return null;
  }

  static String? _checkIngredient(BuildContext context, int index, List<IngredientRowData> ingredientRows) {
    final name = ingredientRows[index].nameController.text.trim().toLowerCase();
    if (name.length < 2) return null;
    final otherBatch = ingredientRows.asMap().entries.any((e) => e.key != index && e.value.nameController.text.trim().toLowerCase() == name);
    if (otherBatch) return 'Дубликат сырья в строках массового ввода';
    final ingState = context.read<IngredientBloc>().state;
    if (ingState is IngredientLoaded && ingState.ingredients.where((i) => !i.isRetail && !i.isArchived).any((i) => i.name.trim().toLowerCase() == name)) {
      return 'Сырье «$name» уже есть на складе';
    }
    return null;
  }

  static String? _checkCategory(BuildContext context, int index, List<CategoryRowData> categoryRows) {
    final name = categoryRows[index].nameController.text.trim().toLowerCase();
    if (name.length < 2) return null;
    final otherBatch = categoryRows.asMap().entries.any((e) => e.key != index && e.value.nameController.text.trim().toLowerCase() == name);
    if (otherBatch) return 'Дубликат категории в строках массового ввода';
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded && catState.categories.where((c) => !c.isArchived).any((c) => c.name.trim().toLowerCase() == name)) {
      return 'Категория «$name» уже существует';
    }
    return null;
  }
}
