// ==============================================================================
// 1. ИМПОРТЫ И ТЕСТОВЫЙ КОНТЕКСТ
// ==============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/write_off/write_off_items_table.dart';

void main() {
  group('WriteOff & Inventory Hybrid Model Tests', () {
    final tomato = Ingredient(
      id: 101,
      name: 'Томаты свежие',
      unit: 'кг',
      costPerUnit: 120.0,
      currentStock: 15.0,
      minStockAlert: 0.0,
      isLowStock: false,
      categoryName: 'Овощи',
    );

    final cola = Ingredient(
      id: 202,
      name: 'Rc Cola 1 л',
      unit: 'шт',
      costPerUnit: 60.0,
      currentStock: 10.0,
      minStockAlert: 0.0,
      isLowStock: false,
      categoryName: 'Напитки',
    );

    // ============================================================================
    // 2. ТЕСТЫ СТРОКИ СПИСАНИЯ
    // ============================================================================
    test('WriteOffItemEntry computes cost and total correctly', () {
      final entry = WriteOffItemEntry(item: tomato, quantity: 2.5);

      expect(entry.cost, 120.0);
      expect(entry.total, 300.0);
      expect(entry.controller.text, '2.5');

      entry.quantity = 4.0;
      expect(entry.total, 480.0);
    });

    test('WriteOffItemEntry integer quantities format cleanly without .0', () {
      final entry = WriteOffItemEntry(item: cola, quantity: 5.0);
      expect(entry.controller.text, '5');
      expect(entry.total, 300.0);
    });

    // ============================================================================
    // 3. ТЕСТЫ СИНХРОНИЗАЦИИ КАТЕГОРИЙ И СПИСКА СПИСАНИЯ
    // ============================================================================
    test('Category quantity change updates existing entry or creates new one',
        () {
      final entries = <WriteOffItemEntry>[];

      // 1. Добавление новой позиции из категории
      void updateQty(Ingredient item, double qty) {
        final idx = entries.indexWhere((e) => e.item.id == item.id);
        if (idx != -1) {
          if (qty <= 0) {
            entries.removeAt(idx);
          } else {
            entries[idx].quantity = qty;
          }
        } else if (qty > 0) {
          entries.add(WriteOffItemEntry(item: item, quantity: qty));
        }
      }

      updateQty(tomato, 3.0);
      expect(entries.length, 1);
      expect(entries.first.item.id, 101);
      expect(entries.first.quantity, 3.0);
      expect(entries.first.total, 360.0);

      // 2. Обновление количества
      updateQty(tomato, 5.0);
      expect(entries.length, 1);
      expect(entries.first.quantity, 5.0);
      expect(entries.first.total, 600.0);

      // 3. Добавление второго товара
      updateQty(cola, 2.0);
      expect(entries.length, 2);

      // 4. Сброс до нуля удаляет позицию из акта
      updateQty(tomato, 0.0);
      expect(entries.length, 1);
      expect(entries.first.item.id, 202);
    });

    // ============================================================================
    // 4. ТЕСТЫ ГРУППИРОВКИ ИНВЕНТАРИЗАЦИИ
    // ============================================================================
    test('Category grouping splits ingredients accurately by categoryName', () {
      final items = [tomato, cola];
      final Map<String, List<Ingredient>> grouped = {};

      for (final it in items) {
        final cat = it.categoryName ?? 'Без категории';
        grouped.putIfAbsent(cat, () => []).add(it);
      }

      expect(grouped.keys.length, 2);
      expect(grouped['Овощи']?.first.name, 'Томаты свежие');
      expect(grouped['Напитки']?.first.name, 'Rc Cola 1 л');
    });

    // ============================================================================
    // 5. ТЕСТЫ ЗАЩИТЫ ОТ КОЛЛИЗИЙ ID (СЫРЬЕ VS РОЗНИЧНЫЙ ТОВАР)
    // ============================================================================
    test('uniqueKey and isSameAs prevent collision when raw and retail have same ID', () {
      final rawBurger = Ingredient(
        id: 1,
        name: 'Говяжья котлета',
        unit: 'шт',
        costPerUnit: 150.0,
        currentStock: 20.0,
        minStockAlert: 5.0,
        isLowStock: false,
        categoryName: 'Мясо',
      );

      final retailCola = Ingredient(
        id: 1,
        name: 'Rc Cola',
        unit: 'шт',
        costPerUnit: 40.0,
        currentStock: 30.0,
        minStockAlert: 5.0,
        isLowStock: false,
        attributes: {'is_retail': true},
        categoryName: 'Без категории',
      );

      // Проверка различия уникальных ключей и предикатов совпадения
      expect(rawBurger.id, equals(retailCola.id));
      expect(rawBurger.uniqueKey, equals('ingredient_1'));
      expect(retailCola.uniqueKey, equals('retail_1'));
      expect(rawBurger.uniqueKey, isNot(equals(retailCola.uniqueKey)));
      expect(rawBurger.isSameAs(retailCola), isFalse);

      // Изоляция контроллеров в слепой инвентаризации
      final controllers = <String, String>{};
      controllers[rawBurger.uniqueKey] = '5';
      expect(controllers.containsKey(retailCola.uniqueKey), isFalse);

      int filledCount = 0;
      for (final item in [rawBurger, retailCola]) {
        if (controllers[item.uniqueKey]?.isNotEmpty == true) {
          filledCount++;
        }
      }
      // [ИНВАРИАНТ] Должно быть ровно 1, а не 2
      expect(filledCount, equals(1));
    });
  });
}
