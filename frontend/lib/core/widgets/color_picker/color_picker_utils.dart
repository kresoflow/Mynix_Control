// ==============================================================================
// Title: ColorPickerUtils (color_picker_utils.dart)
// Path: frontend/lib/core/widgets/color_picker/color_picker_utils.dart
// Description: Утилиты конвертации, парсинга и кэширования HEX-цветов категорий.
// ==============================================================================

import 'package:flutter/material.dart';

class ColorPickerUtils {
  static final Map<String, Color> _hexColorCache = {};

  /// Converts a Color to a standard 6-char HEX string with leading '#' (e.g. #FF5A00)
  static String toHex(Color color) {
    final r = (color.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  /// Parses a HEX string (#FF5A00, FF5A00, #F5A) into a Flutter Color with O(1) caching
  static Color? parseHex(String? hexString) {
    if (hexString == null || hexString.trim().isEmpty) return null;
    final cached = _hexColorCache[hexString];
    if (cached != null) return cached;

    var clean = hexString.replaceAll('#', '').trim();
    if (clean.length == 3) {
      clean = clean.split('').map((c) => '$c$c').join();
    }
    if (clean.length == 6) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) {
        final color = Color(val | 0xFF000000);
        _hexColorCache[hexString] = color;
        return color;
      }
    } else if (clean.length == 8) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) {
        final color = Color(val);
        _hexColorCache[hexString] = color;
        return color;
      }
    }
    return null;
  }

  /// 16 Recommended Commercial Restaurant & Food Palette Presets
  static const List<ColorPreset> commercialPresets = [
    ColorPreset('Бургеры / Мясо', Color(0xFFE65100)),
    ColorPreset('Пицца / Огонь', Color(0xFFEA580C)),
    ColorPreset('Хот-доги / Гриль', Color(0xFFF59E0B)),
    ColorPreset('Выпечка / Золото', Color(0xFFD97706)),
    ColorPreset('Напитки / Океан', Color(0xFF0284C7)),
    ColorPreset('Коктейли / Неон', Color(0xFF06B6D4)),
    ColorPreset('Кофе / Мокко', Color(0xFF78350F)),
    ColorPreset('Чай / Карамель', Color(0xFFB45309)),
    ColorPreset('Зелень / Салаты', Color(0xFF10B981)),
    ColorPreset('Авокадо / Лайм', Color(0xFF84CC16)),
    ColorPreset('Десерты / Ягоды', Color(0xFFE11D48)),
    ColorPreset('Мороженое / Коралл', Color(0xFFF43F5E)),
    ColorPreset('Сладости / Малина', Color(0xFFD946EF)),
    ColorPreset('Премиум / Фиолет', Color(0xFF8B5CF6)),
    ColorPreset('Графит / Стейк', Color(0xFF475569)),
    ColorPreset('Уголь / Барбекю', Color(0xFF1E293B)),
  ];
}

class ColorPreset {
  final String title;
  final Color color;
  const ColorPreset(this.title, this.color);
}
