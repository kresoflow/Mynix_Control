// ==============================================================================
// МОДУЛЬ: Ядро системы / Стандартизация и форматирование единиц измерения (UOM)
// ДОМЕН: lib/core/utils/unit_formatter.dart
// ==============================================================================

import 'package:flutter/material.dart';

/// Единый источник истины (SSOT) для единиц измерения в UI Kreso Flow.
/// 
/// Строгий иерархический порядок (Объем -> Вес -> Штуки):
/// 1. л   (l)   — литры (крупный объем)
/// 2. мл  (ml)  — миллилитры (малый объем)
/// 3. кг  (kg)  — килограммы (крупный вес)
/// 4. г   (g)   — граммы (малый вес)
/// 5. шт  (pcs) — штуки (неделимые единицы)
class UnitFormatter {
  // ─── 1. Канонический упорядоченный список единиц ─────────────────────────────

  /// Список пар (DB-ключ -> UI-символ) в утвержденном порядке: л -> мл -> кг -> г -> шт
  static const List<MapEntry<String, String>> orderedUnits = [
    MapEntry('l', 'л'),
    MapEntry('ml', 'мл'),
    MapEntry('kg', 'кг'),
    MapEntry('g', 'г'),
    MapEntry('pcs', 'шт'),
  ];

  /// Список строковых UI-символов в том же порядке
  static const List<String> orderedUiSymbols = ['л', 'мл', 'кг', 'г', 'шт'];

  /// Внутренний словарь маппинга различных вариаций ключей БД в единый UI-символ
  static const Map<String, String> _dbToUi = {
    'l': 'л',
    'л': 'л',
    'ml': 'мл',
    'мл': 'мл',
    'kg': 'кг',
    'кг': 'кг',
    'g': 'г',
    'gr': 'г',
    'г': 'г',
    'pcs': 'шт',
    'pc': 'шт',
    'шт': 'шт',
    'portion': 'порц',
    'порц': 'порц',
    'порция': 'порц',
  };

  /// Словарь нормализации любых вариаций в канонический DB-ключ ('l', 'ml', 'kg', 'g', 'pcs')
  static const Map<String, String> _toDbKeyMap = {
    'l': 'l',
    'литр': 'l',
    'л': 'l',
    'ml': 'ml',
    'мл': 'ml',
    'миллилитр': 'ml',
    'kg': 'kg',
    'кг': 'kg',
    'килограмм': 'kg',
    'g': 'g',
    'gr': 'g',
    'г': 'g',
    'грамм': 'g',
    'pcs': 'pcs',
    'pc': 'pcs',
    'шт': 'pcs',
    'штук': 'pcs',
    'штука': 'pcs',
  };

  /// Дефолтная единица для товаров витрины/ритейла (штучные товары)
  static const String defaultRetailUnit = 'pcs';

  /// Дефолтная единица для сырья/кухни (весовые ингредиенты)
  static const String defaultIngredientUnit = 'g';

  // ─── 2. Методы форматирования и конвертации ──────────────────────────────────

  /// Преобразует любую строку (верхний регистр, кириллицу, 'PCS', 'ШТ')
  /// в канонический ключ БД ('pcs', 'g', 'kg', 'ml', 'l').
  static String toDbKey(String? unit, [String fallback = 'pcs']) {
    if (unit == null || unit.trim().isEmpty) return fallback;
    final normalized = unit.trim().toLowerCase();
    return _toDbKeyMap[normalized] ?? fallback;
  }

  /// Универсальный расчет коэффициента пересчета между единицами склада (кг <-> г, л <-> мл)
  static double getConversionFactor(String fromUnit, String toUnit) {
    final from = toDbKey(fromUnit);
    final to = toDbKey(toUnit);
    if (from == to) return 1.0;
    if (from == 'kg' && to == 'g') return 1000.0;
    if (from == 'g' && to == 'kg') return 0.001;
    if (from == 'l' && to == 'ml') return 1000.0;
    if (from == 'ml' && to == 'l') return 0.001;
    return 1.0;
  }

  /// Преобразует сырой ключ БД (или строку) в компактный русский символ
  static String format(String? unit) {
    if (unit == null || unit.trim().isEmpty) return 'шт';
    final normalized = unit.trim().toLowerCase();
    return _dbToUi[normalized] ?? unit;
  }

  /// Форматирует количество вместе с локализованной единицей измерения (напр. "0.015 кг", "1.5 л", "2 шт")
  static String formatAmount(num amount, String? unit) {
    if (amount == 0) return '0 ${format(unit)}';
    final isInt = amount.truncateToDouble() == amount;
    final String qtyStr;
    if (isInt) {
      qtyStr = amount.toInt().toString();
    } else {
      final str = amount.toDouble().toStringAsFixed(3);
      final trimmed = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      qtyStr = trimmed.isEmpty ? '0' : trimmed;
    }
    return '$qtyStr ${format(unit)}';
  }

  // ─── 3. Генераторы элементов выпадающих списков ─────────────────────────────

  /// Элементы для DropdownButtonFormField, где value = ключ БД ('l', 'ml', 'kg', 'g', 'pcs')
  static List<DropdownMenuItem<String>> get dropdownItems => orderedUnits
      .map(
        (e) => DropdownMenuItem<String>(
          value: e.key,
          child: Text(
            e.value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      )
      .toList();

  /// Элементы для DropdownButtonFormField, где value = русский символ ('л', 'мл', 'кг', 'г', 'шт')
  static List<DropdownMenuItem<String>> get uiDropdownItems => orderedUiSymbols
      .map(
        (sym) => DropdownMenuItem<String>(
          value: sym,
          child: Text(
            sym,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      )
      .toList();
}
