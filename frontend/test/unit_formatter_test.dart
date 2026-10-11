// ==============================================================================
// ТЕСТЫ: Единый стандарт единиц измерения (UnitFormatter SSOT)
// ДОМЕН: test/unit_formatter_test.dart
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

void main() {
  group('UnitFormatter Specification & SSOT Invariants', () {
    // ─── 1. Иерархия и порядок единиц ──────────────────────────────────────────

    test('orderedUnits adheres strictly to reverse scale: л -> мл -> кг -> г -> шт', () {
      final keys = UnitFormatter.orderedUnits.map((e) => e.key).toList();
      final labels = UnitFormatter.orderedUnits.map((e) => e.value).toList();

      expect(keys, equals(['l', 'ml', 'kg', 'g', 'pcs']));
      expect(labels, equals(['л', 'мл', 'кг', 'г', 'шт']));
      expect(UnitFormatter.orderedUiSymbols, equals(['л', 'мл', 'кг', 'г', 'шт']));
    });

    test('dropdownItems generates DropdownMenuItems in exact canonical order', () {
      final items = UnitFormatter.dropdownItems;
      expect(items.length, equals(5));
      expect(items[0].value, equals('l'));
      expect(items[1].value, equals('ml'));
      expect(items[2].value, equals('kg'));
      expect(items[3].value, equals('g'));
      expect(items[4].value, equals('pcs'));
    });

    // ─── 2. Форматирование UI-символов и количеств ─────────────────────────────

    test('format maps DB keys and synonyms correctly', () {
      expect(UnitFormatter.format('l'), equals('л'));
      expect(UnitFormatter.format('ml'), equals('мл'));
      expect(UnitFormatter.format('kg'), equals('кг'));
      expect(UnitFormatter.format('g'), equals('г'));
      expect(UnitFormatter.format('gr'), equals('г'));
      expect(UnitFormatter.format('pcs'), equals('шт'));
      expect(UnitFormatter.format('pc'), equals('шт'));
      expect(UnitFormatter.format('PCS'), equals('шт'));
      expect(UnitFormatter.format('KG'), equals('кг'));
      expect(UnitFormatter.format(null), equals('шт'));
    });

    test('formatAmount renders integers without trailing zeros and decimals with up to 3 digits', () {
      expect(UnitFormatter.formatAmount(2000, 'g'), equals('2000 г'));
      expect(UnitFormatter.formatAmount(10.0, 'kg'), equals('10 кг'));
      expect(UnitFormatter.formatAmount(0.0, 'pcs'), equals('0 шт'));
      expect(UnitFormatter.formatAmount(1.5, 'l'), equals('1.5 л'));
      expect(UnitFormatter.formatAmount(250.75, 'ml'), equals('250.75 мл'));
      expect(UnitFormatter.formatAmount(0.015, 'kg'), equals('0.015 кг'));
      expect(UnitFormatter.formatAmount(0.005, 'kg'), equals('0.005 кг'));
    });

    // ─── 3. Нормализация toDbKey ───────────────────────────────────────────────

    test('toDbKey normalizes uppercase DB values, Russian labels, and variants', () {
      expect(UnitFormatter.toDbKey('PCS'), equals('pcs'));
      expect(UnitFormatter.toDbKey('ШТ'), equals('pcs'));
      expect(UnitFormatter.toDbKey('шт'), equals('pcs'));
      expect(UnitFormatter.toDbKey('KG'), equals('kg'));
      expect(UnitFormatter.toDbKey('кг'), equals('kg'));
      expect(UnitFormatter.toDbKey('G'), equals('g'));
      expect(UnitFormatter.toDbKey('г'), equals('g'));
      expect(UnitFormatter.toDbKey('ML'), equals('ml'));
      expect(UnitFormatter.toDbKey('мл'), equals('ml'));
      expect(UnitFormatter.toDbKey('L'), equals('l'));
      expect(UnitFormatter.toDbKey('л'), equals('l'));
      expect(UnitFormatter.toDbKey(null, 'g'), equals('g'));
    });

    // ─── 4. Коэффициенты пересчета склада ──────────────────────────────────────

    test('getConversionFactor calculates correct factors regardless of casing or locale', () {
      expect(UnitFormatter.getConversionFactor('кг', 'г'), equals(1000.0));
      expect(UnitFormatter.getConversionFactor('kg', 'g'), equals(1000.0));
      expect(UnitFormatter.getConversionFactor('KG', 'g'), equals(1000.0));
      expect(UnitFormatter.getConversionFactor('кг', 'G'), equals(1000.0));

      expect(UnitFormatter.getConversionFactor('г', 'кг'), equals(0.001));
      expect(UnitFormatter.getConversionFactor('g', 'kg'), equals(0.001));

      expect(UnitFormatter.getConversionFactor('л', 'мл'), equals(1000.0));
      expect(UnitFormatter.getConversionFactor('ml', 'l'), equals(0.001));

      expect(UnitFormatter.getConversionFactor('pcs', 'pcs'), equals(1.0));
      expect(UnitFormatter.getConversionFactor('шт', 'pcs'), equals(1.0));
    });

    // ─── 5. Интеграция с моделью Ingredient ───────────────────────────────────

    test('Ingredient.fromJson automatically normalizes uppercase unit to canonical key', () {
      final jsonWithUppercase = {
        'id': 54,
        'name': 'Сыр чеддер',
        'unit': 'G',
        'current_stock': 2000.0,
        'min_stock_alert': 500.0,
        'cost_per_unit': 0.3,
      };

      final ing = Ingredient.fromJson(jsonWithUppercase);
      expect(ing.unit, equals('g'));
      expect(UnitFormatter.format(ing.unit), equals('г'));
      expect(UnitFormatter.formatAmount(ing.currentStock, ing.unit), equals('2000 г'));
    });
  });
}
