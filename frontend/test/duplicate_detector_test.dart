// ==============================================================================
// ТЕСТЫ: Сервис поиска дубликатов позиций меню, сырья и категорий
// ДОМЕН: test/duplicate_detector_test.dart
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

void main() {
  group('DuplicateDetector Unit Tests', () {
    // ─── 1. Базовая детекция и изоляция доменов ──────────────────────────────

    test('findMenuItemDuplicate detects name collision for dishes', () {
      final items = [
        const MenuItem(
          id: 1,
          name: 'Капучино 200мл',
          price: 250,
          categoryId: '1',
          categoryName: 'Кофе',
        ),
      ];

      final match = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: '  капучино  200мл  ',
        isRetail: false,
      );

      expect(match, isNotNull);
      expect(match!.item.id, equals(1));
      expect(match.matchReason, contains('уже существует'));
    });

    test('findMenuItemDuplicate isolates domains (dish does not block retail product)', () {
      final items = [
        const MenuItem(
          id: 1,
          name: 'Тропик',
          price: 150,
          categoryId: '1',
        ),
      ];

      // Проверка создания товара витрины с тем же именем, что и у блюда кухни
      final retailMatch = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Тропик',
        isRetail: true,
      );
      expect(retailMatch, isNull);
    });

    // ─── 2. Игнорирование архива (Poka-Yoke) ──────────────────────────────────

    test('findMenuItemDuplicate ignores archived items (isAvailable == false)', () {
      final items = [
        const MenuItem(
          id: 99,
          name: 'Архивный Лимонад',
          price: 100,
          categoryId: '1',
          isAvailable: false, // В архиве
        ),
      ];

      final match = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Архивный Лимонад',
        isRetail: false,
      );

      expect(match, isNull, reason: 'Позиции из архива не должны триггерить алерт дубликата');
    });

    test('findIngredientDuplicate and findCategoryDuplicate ignore archived records', () {
      final ingredients = [
        Ingredient(
          id: 10,
          name: 'Архивный Сахар',
          unit: 'kg',
          currentStock: 0,
          minStockAlert: 0,
          costPerUnit: 50,
          isLowStock: false,
          isArchived: true,
        ),
      ];

      final ingMatch = DuplicateDetector.findIngredientDuplicate(
        ingredients: ingredients,
        queryName: 'Архивный Сахар',
      );
      expect(ingMatch, isNull);

      final categories = [
        MenuCategory(
          id: 5,
          name: 'Архивная папка',
          categoryType: 'dish',
          sortOrder: 0,
          isArchived: true,
        ),
      ];

      final catMatch = DuplicateDetector.findCategoryDuplicate(
        categories: categories,
        queryName: 'Архивная папка',
        categoryType: 'dish',
      );
      expect(catMatch, isNull);
    });

    // ─── 3. Глубокий парсинг массива вариаций и нормализация единиц ───────────

    test('findMenuItemDuplicate normalizes volume units (0.5 == 0.5л == 0.5 л)', () {
      final items = [
        const MenuItem(
          id: 20,
          name: 'Тропик|TYPE|retail',
          price: 100,
          categoryId: '2',
          categoryName: 'Напитки',
          attributesJson: '{"flavor": "манго", "variations": [{"name": "0.5 л", "price": 100}, {"name": "1.0 л", "price": 180}]}',
        ),
      ];

      // Вариант 1: Ввод без единиц '0.5' должен найти '0.5 л'
      final matchNoUnit = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Тропик',
        isRetail: true,
        queryFlavor: 'манго',
        queryVolume: '0.5',
      );
      expect(matchNoUnit, isNotNull);
      expect(matchNoUnit!.item.id, equals(20));

      // Вариант 2: Ввод со слитной единицей '0.5л'
      final matchMerged = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Тропик',
        isRetail: true,
        queryFlavor: 'манго',
        queryVolume: '0.5л',
      );
      expect(matchMerged, isNotNull);

      // Вариант 3: Другой объем '0.33 л' не должен триггерить дубликат
      final matchDiffVol = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Тропик',
        isRetail: true,
        queryFlavor: 'манго',
        queryVolume: '0.33 л',
      );
      expect(matchDiffVol, isNull);
    });

    // ─── 4. Контекст категории при меж-категорийных дубликатах ────────────────

    test('findMenuItemDuplicate includes category context when duplicate is in another category', () {
      final items = [
        const MenuItem(
          id: 50,
          name: 'Сэндвич с тунцом',
          price: 320,
          categoryId: '10',
          categoryName: 'Закуски',
        ),
      ];

      // Пользователь создает блюдо в категории id: 20 (Десерты)
      final match = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Сэндвич с тунцом',
        isRetail: false,
        currentCategoryId: 20,
      );

      expect(match, isNotNull);
      expect(match!.isSameCategory, isFalse);
      expect(match.matchReason, contains('в категории «Закуски»'));
    });

    // ─── 5. Редактирование и штрихкоды ────────────────────────────────────────

    test('findMenuItemDuplicate ignores self and child variations when editing', () {
      final items = [
        const MenuItem(
          id: 10,
          name: 'Американо',
          price: 200,
          categoryId: '1',
        ),
        const MenuItem(
          id: 11,
          parentId: 10,
          name: 'Американо 300мл',
          price: 250,
          categoryId: '1',
        ),
      ];

      final selfMatch = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Американо',
        excludeItemId: 10,
      );
      expect(selfMatch, isNull);

      final childMatch = DuplicateDetector.findMenuItemDuplicate(
        items: items,
        queryName: 'Американо 300мл',
        excludeItemId: 10,
      );
      expect(childMatch, isNull);
    });

    test('findIngredientDuplicate detects barcode collision', () {
      final ingredients = [
        Ingredient(
          id: 5,
          name: 'Сироп Ваниль',
          unit: 'l',
          barcode: '4607001002003',
          currentStock: 10,
          minStockAlert: 2,
          costPerUnit: 450,
          isLowStock: false,
        ),
      ];

      final match = DuplicateDetector.findIngredientDuplicate(
        ingredients: ingredients,
        queryName: 'Другой сироп',
        queryBarcode: '4607001002003',
      );

      expect(match, isNotNull);
      expect(match!.matchReason, contains('Штрихкод совпадает'));
    });
  });
}
