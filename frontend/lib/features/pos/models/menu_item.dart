import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

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
  });

  @override
  List<Object?> get props => [id, name, price, categoryId, categoryName, shortName, tags, attributesJson, isAvailable, barcode, parentId];

  String get cleanName {
    return name.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0];
  }

  String? get attributesString {
    if (attributesJson != null && attributesJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> attrs = jsonDecode(attributesJson!);
        if (attrs['flavor'] != null && attrs['flavor'].toString().isNotEmpty) {
          return attrs['flavor'].toString();
        }
        if (attrs['modifier_groups'] != null) {
          final groups = attrs['modifier_groups'] as List;
          for (var group in groups) {
            if (group['name'] == 'Вкус') {
              final modifiers = group['modifiers'] as List;
              if (modifiers.isNotEmpty) {
                return modifiers.first['name'].toString();
              }
            }
          }
        }
      } catch (_) {}
    }

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
}

