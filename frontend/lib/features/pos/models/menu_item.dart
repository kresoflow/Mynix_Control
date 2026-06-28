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

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.categoryName,
    this.shortName,
    this.tags,
  });

  @override
  List<Object?> get props => [id, name, price, categoryId, categoryName, shortName, tags];

  String get cleanName {
    return name.split('|TYPE|')[0].split('|ATTR|')[0].split('|ICON|')[0];
  }

  String? get attributesString {
    final noType = name.split('|TYPE|')[0];
    if (noType.contains('|ATTR|')) {
      return noType.split('|ATTR|')[1].split('|ICON|')[0];
    }
    return null;
  }

  String? get icon {
    if (name.contains('|ICON|')) {
      return name.split('|ICON|')[1].split('|TYPE|')[0].split('|ATTR|')[0].replaceAll('icon:', '');
    }
    return null;
  }

  bool get isRetail {
    return name.contains('|TYPE|retail');
  }
}

