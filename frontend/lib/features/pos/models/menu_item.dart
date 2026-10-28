import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';

part 'menu_item.g.dart';

@HiveType(typeId: 0)
class MenuItem extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final String? categoryName;

  @HiveField(5)
  final String? shortName;

  @HiveField(6)
  final List<String>? tags;

  @HiveField(7)
  final String? attributesJson;

  @HiveField(8, defaultValue: true)
  final bool isAvailable;

  @HiveField(9)
  final String? barcode;

  @HiveField(10)
  final int? parentId;

  @HiveField(11, defaultValue: 0)
  final int sortOrder;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.categoryName,
    this.shortName,
    this.tags,
    this.attributesJson,
    this.isAvailable = true,
    this.barcode,
    this.parentId,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, price, categoryId, categoryName, shortName, tags, attributesJson, isAvailable, barcode, parentId, sortOrder];

  String get cleanName {
    return name.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0];
  }

  /// Извлекает название вкуса из атрибутов или групп модификаторов.
  ///
  /// [ИНВАРИАНТ] Для товаров витрины вкус хранится в `attrs['flavor']` либо в модификаторе 'Вкус'.
  String? get flavorString {
    if (attributesJson != null && attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(attributesJson!);
        if (attrs['flavor'] != null && attrs['flavor'].toString().trim().isNotEmpty) {
          return attrs['flavor'].toString().trim();
        }
        if (attrs['modifier_groups'] != null) {
          final groups = attrs['modifier_groups'] as List;
          for (var group in groups) {
            if (group['name'] == 'Вкус') {
              final modifiers = group['modifiers'] as List;
              if (modifiers.isNotEmpty) {
                return modifiers.first['name'].toString().trim();
              }
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Возвращает список меток вариаций (фасовок) без повторения названия товара и вкуса.
  List<String> get variationLabels {
    final List<String> labels = [];
    final flavor = flavorString;
    if (attributesJson != null && attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(attributesJson!);
        if (attrs['variations'] != null && attrs['variations'] is List) {
          final vars = attrs['variations'] as List;
          for (var v in vars) {
            if (v is Map && v['name'] != null) {
              String vName = v['name'].toString().trim();
              final cName = cleanName.trim();
              if (vName.startsWith(cName)) {
                vName = vName.substring(cName.length).trim();
              }
              if (vName.startsWith('(') && vName.endsWith(')')) {
                vName = vName.substring(1, vName.length - 1).trim();
              }
              if (flavor != null && flavor.isNotEmpty && vName.startsWith(flavor)) {
                vName = vName.substring(flavor.length).trim();
              }
              if (vName.startsWith('•')) {
                vName = vName.substring(1).trim();
              }
              if (vName.isNotEmpty) {
                labels.add(vName);
              }
            }
          }
        } else if (attrs['volume'] != null && attrs['volume'].toString().trim().isNotEmpty) {
          labels.add(attrs['volume'].toString().trim());
        } else if (attrs['unit'] != null && attrs['unit'].toString().trim().isNotEmpty && attrs['unit'] != 'pcs') {
          final u = attrs['unit'].toString().trim();
          labels.add(UnitFormatter.format(u));
        }
      } catch (_) {}
    }
    return labels;
  }

  /// Краткая сводка вариаций/фасовок для карточки каталога и витрины.
  ///
  /// [UI-KIT] Форматирует список фасовок:
  /// - 1 вариация: "100г"
  /// - 2–3 вариации: "50г  200г  300г"
  /// - 4+ вариаций: "N вариаций"
  String? get variationsSummary {
    final labels = variationLabels;
    if (labels.isEmpty) return null;
    if (labels.length == 1) {
      return labels.first;
    } else if (labels.length <= 3) {
      return labels.join('  ');
    } else {
      return '${labels.length} вариаций';
    }
  }

  /// Полная строка атрибутов (Вкус • Фасовка).
  String? get attributesString {
    final f = flavorString;
    final v = variationsSummary;
    if (f != null && f.isNotEmpty && v != null && v.isNotEmpty) {
      return '$f • $v';
    }
    if (f != null && f.isNotEmpty) return f;
    if (v != null && v.isNotEmpty) return v;

    final noType = name.split('|TYPE|')[0];
    if (noType.contains('|ATTR|')) {
      final attrStr = noType.split('|ATTR|')[1].split('|ICON|')[0];
      if (attrStr.startsWith('[{') || attrStr.startsWith('{')) return null;
      return attrStr;
    }
    return null;
  }

  String? get icon {
    if (name.contains('|ICON|')) {
      final parsed = name.split('|ICON|')[1].split('|TYPE|')[0].split('|ATTR|')[0].replaceAll('icon:', '').trim();
      if (parsed.isEmpty || parsed == 'null' || parsed == 'none' || parsed == 'undefined') return null;
      return parsed;
    }
    return null;
  }

  bool get isRetail {
    return name.contains('|TYPE|retail');
  }

  List<double>? get variationPrices {
    if (attributesJson != null && attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(attributesJson!);
        if (attrs['variations'] != null && attrs['variations'] is List) {
          final vars = attrs['variations'] as List;
          return vars.map((v) => (v['price'] as num?)?.toDouble() ?? 0.0).toList();
        }
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>>? get variations {
    if (attributesJson != null && attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(attributesJson!);
        if (attrs['variations'] != null && attrs['variations'] is List) {
          return List<Map<String, dynamic>>.from(
            (attrs['variations'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
          );
        }
      } catch (_) {}
    }
    return null;
  }

  bool get hasVariations => variations != null && variations!.isNotEmpty;

  Map<String, dynamic>? get attributes {
    if (attributesJson != null && attributesJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(attributesJson!);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  String get stockUnit => attributes?['stock_unit']?.toString() ?? attributes?['unit']?.toString() ?? 'pcs';
  String get displayUnit => attributes?['display_unit']?.toString() ?? attributes?['unit']?.toString() ?? 'pcs';

  bool get hasModifiers {
    if (attributesJson != null && attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(attributesJson!);
        final groups = attrs['modifier_groups'] as List?;
        return groups != null && groups.isNotEmpty;
      } catch (_) {}
    }
    return false;
  }
}

