// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 0;

  @override
  MenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItem(
      id: fields[0] as int,
      name: fields[1] as String,
      price: fields[2] as double,
      categoryId: fields[3] as String,
      categoryName: fields[4] as String?,
      shortName: fields[5] as String?,
      tags: (fields[6] as List?)?.cast<String>(),
      attributesJson: fields[7] as String?,
      isAvailable: fields[8] == null ? true : fields[8] as bool,
      barcode: fields[9] as String?,
      parentId: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.categoryName)
      ..writeByte(5)
      ..write(obj.shortName)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.attributesJson)
      ..writeByte(8)
      ..write(obj.isAvailable)
      ..writeByte(9)
      ..write(obj.barcode)
      ..writeByte(10)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
