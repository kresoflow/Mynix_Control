// ==============================================================================
// МОДУЛЬ: Каталог / Детектор дубликатов (Duplicate Detection Engine)
// ДОМЕН: lib/features/menu/services/duplicate_detector.dart
// ==============================================================================

import 'dart:convert';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ─── 1. Модель совпадения дубликата ──────────────────────────────────────────

/// Результат поиска дубликата с указанием причины и контекста категории.
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

// ─── 2. Сервис детектора дубликатов ──────────────────────────────────────────

/// Сервис предотвращения дублирования позиций меню, сырья и категорий.
///
/// [ИНВАРИАНТ] Игнорирует архивные позиции (isAvailable == false, isArchived == true).
/// [ИНВАРИАНТ] Для товаров витрины парсит массив вариаций и нормализует единицы измерения (0.5 == 0.5л == 0.5 л).
class DuplicateDetector {
  // ─── Поиск дубликатов позиций меню / товаров витрины ──────────────────────

  /// Выполняет поиск дубликата среди позиций каталога.
  static DuplicateMatch<MenuItem>? findMenuItemDuplicate({
    required List<MenuItem> items,
    required String queryName,
    bool isRetail = false,
    String? queryFlavor,
    String? queryVolume,
    String? queryBarcode,
    int? currentCategoryId,
    int? excludeItemId,
  }) {
    final cleanQuery = _normalize(queryName);
    final cleanBarcode = queryBarcode?.trim();
    final cleanFlavor = queryFlavor != null ? _normalize(queryFlavor) : '';
    final cleanVolume = queryVolume != null ? queryVolume.trim() : '';

    if (cleanQuery.length < 2 && (cleanBarcode == null || cleanBarcode.isEmpty)) {
      return null;
    }

    for (final item in items) {
      // [ИНВАРИАНТ] Проверка только среди активных позиций (игнорируем архив)
      if (!item.isAvailable) continue;

      // Изоляция доменов: кухня vs витрина
      if (item.isRetail != isRetail) continue;

      // Игнорируем редактируемый элемент и его дочерние вариации
      if (excludeItemId != null) {
        if (item.id == excludeItemId) continue;
        if (item.parentId != null && item.parentId == excludeItemId) continue;
      }

      final isSameCategory = currentCategoryId == null || item.categoryId == currentCategoryId.toString();
      final catContext = (!isSameCategory && item.categoryName != null && item.categoryName!.trim().isNotEmpty)
          ? ' в категории «${item.categoryName}»'
          : (!isSameCategory ? ' в другой категории' : '');

      // 1. Проверка по штрихкоду
      if (cleanBarcode != null && cleanBarcode.isNotEmpty && item.barcode != null && item.barcode!.trim() == cleanBarcode) {
        return DuplicateMatch(
          item: item,
          matchReason: 'Штрихкод совпадает с «${item.cleanName}»$catContext',
          isSameCategory: isSameCategory,
          categoryName: item.categoryName,
        );
      }

      // 2. Проверка по наименованию и атрибутам
      final itemClean = _normalize(item.cleanName);
      if (cleanQuery.isNotEmpty && itemClean == cleanQuery) {
        if (isRetail) {
          // [ИНВАРИАНТ] Для витрины дубликат фиксируется ТОЛЬКО при совпадении Названия, Вкуса и Объема
          final itemFlavor = item.flavorString != null ? _normalize(item.flavorString!) : '';
          final itemVolumes = _extractNormalizedVolumes(item);
          final normQueryVolume = normalizeVolume(cleanVolume);

          final bool isSameFlavor = cleanFlavor == itemFlavor;
          final bool isSameVolume = normQueryVolume.isNotEmpty
              ? itemVolumes.contains(normQueryVolume)
              : itemVolumes.isEmpty;

          if (isSameFlavor && isSameVolume) {
            final desc = [
              item.cleanName,
              if (item.flavorString != null && item.flavorString!.isNotEmpty) item.flavorString!,
              if (cleanVolume.isNotEmpty) cleanVolume else if (item.variationsSummary != null) item.variationsSummary!,
            ].join(' ');
            return DuplicateMatch(
              item: item,
              matchReason: isSameCategory
                  ? 'Товар «$desc» уже существует'
                  : 'Товар «$desc» уже есть$catContext',
              isSameCategory: isSameCategory,
              categoryName: item.categoryName,
            );
          }
        } else {
          // Для блюд кухни достаточно совпадения названия
          return DuplicateMatch(
            item: item,
            matchReason: isSameCategory
                ? 'Позиция «${item.cleanName}» уже существует'
                : 'Позиция «${item.cleanName}» уже есть$catContext',
            isSameCategory: isSameCategory,
            categoryName: item.categoryName,
          );
        }
      }
    }

    return null;
  }

  // ─── Поиск дубликатов сырья и ингредиентов ─────────────────────────────────

  /// Выполняет поиск дубликата сырья на складе.
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
      // [ИНВАРИАНТ] Проверка только среди активного сырья (игнорируем архив)
      if (ing.isArchived) continue;
      if (excludeIngredientId != null && ing.id == excludeIngredientId) continue;

      final isSameCategory = currentCategoryId == null || ing.categoryId == currentCategoryId;
      final catContext = (!isSameCategory && ing.categoryName != null && ing.categoryName!.trim().isNotEmpty)
          ? ' в категории «${ing.categoryName}»'
          : (!isSameCategory ? ' в другой категории' : '');

      if (cleanBarcode != null && cleanBarcode.isNotEmpty && ing.barcode != null && ing.barcode!.trim() == cleanBarcode) {
        return DuplicateMatch(
          item: ing,
          matchReason: 'Штрихкод совпадает с «${ing.name}»$catContext',
          isSameCategory: isSameCategory,
          categoryName: ing.categoryName,
        );
      }

      final ingClean = _normalize(ing.name);
      if (cleanQuery.isNotEmpty && ingClean == cleanQuery) {
        return DuplicateMatch(
          item: ing,
          matchReason: isSameCategory
              ? 'Сырье «${ing.name}» уже существует'
              : 'Сырье «${ing.name}» уже есть$catContext',
          isSameCategory: isSameCategory,
          categoryName: ing.categoryName,
        );
      }
    }

    return null;
  }

  // ─── Поиск дубликатов категорий ───────────────────────────────────────────

  /// Выполняет поиск дубликата категории каталога или склада.
  static DuplicateMatch<MenuCategory>? findCategoryDuplicate({
    required List<MenuCategory> categories,
    required String queryName,
    String? categoryType,
    int? excludeCategoryId,
  }) {
    final cleanQuery = _normalize(queryName);
    if (cleanQuery.length < 2) return null;

    for (final cat in categories) {
      // [ИНВАРИАНТ] Проверка только среди активных категорий
      if (cat.isArchived) continue;
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

  // ─── Нормализация и вспомогательные функции ────────────────────────────────

  /// Нормализует строку объема/фасовки для надежного сравнения (0.5 == 0.5л == 0.5 л == 0.50).
  static String normalizeVolume(String input) {
    String clean = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return '';

    // Заменяем запятую на точку и убираем скобки
    clean = clean.replaceAll(',', '.').replaceAll('(', '').replaceAll(')', '');

    // Удаляем единицы измерения в конце строки
    clean = clean.replaceAll(
      RegExp(r'(л|l|мл|ml|кг|kg|гр|г|g|мг|mg|шт|pcs|порц|порций)$', caseSensitive: false),
      '',
    );

    // Извлекаем числовое значение (даже если спереди осталось имя, например "фантаслайм1")
    final matchNum = RegExp(r'(\d+(?:\.\d+)?)$').firstMatch(clean);
    if (matchNum != null) {
      final numVal = double.tryParse(matchNum.group(1)!);
      if (numVal != null) {
        return numVal == numVal.toInt() ? numVal.toInt().toString() : numVal.toString();
      }
    }

    final numVal = double.tryParse(clean);
    if (numVal != null) {
      return numVal == numVal.toInt() ? numVal.toInt().toString() : numVal.toString();
    }

    return clean;
  }

  /// Извлекает нормализованные объемы из всех вариаций товара и сводных атрибутов.
  static List<String> _extractNormalizedVolumes(MenuItem item) {
    final Set<String> volumes = {};

    // 1. Проверяем массив вариаций из JSON attributes
    if (item.variations != null && item.variations!.isNotEmpty) {
      for (final v in item.variations!) {
        if (v['name'] != null) {
          final norm = normalizeVolume(v['name'].toString());
          if (norm.isNotEmpty) volumes.add(norm);
        }
      }
    }

    // 2. Проверяем метки variationLabels
    for (final label in item.variationLabels) {
      final norm = normalizeVolume(label);
      if (norm.isNotEmpty) volumes.add(norm);
    }

    // 3. Проверяем сводную строку вариаций
    if (item.variationsSummary != null && item.variationsSummary!.isNotEmpty) {
      final norm = normalizeVolume(item.variationsSummary!);
      if (norm.isNotEmpty) volumes.add(norm);
    }

    // 4. Проверяем объем из JSON attributes для плоских товаров (Flat SKU)
    if (item.attributesJson != null && item.attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(item.attributesJson!);
        if (attrs['volume'] != null && attrs['volume'].toString().trim().isNotEmpty) {
          final norm = normalizeVolume(attrs['volume'].toString());
          if (norm.isNotEmpty) volumes.add(norm);
        }
      } catch (_) {}
    }

    return volumes.toList();
  }

  /// Базовая нормализация текстовой строки (trim, lowercase, сжатие пробелов).
  static String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
