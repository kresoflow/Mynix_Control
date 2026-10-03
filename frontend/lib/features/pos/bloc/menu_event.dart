// ==============================================================================
// МОДУЛЬ: POS / Меню — События BLoC каталога и меню
// ДОМЕН: lib/features/pos/bloc/menu_event.dart
// ==============================================================================

import 'package:equatable/equatable.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();
  @override
  List<Object?> get props => [];
}

class LoadMenu extends MenuEvent {}

class CreateMenuItem extends MenuEvent {
  final String name;
  final double price;
  final String category;
  final int sortOrder;
  final Map<String, dynamic>? attributes;
  final String? barcode;

  const CreateMenuItem({
    required this.name,
    required this.price,
    required this.category,
    this.sortOrder = 0,
    this.attributes,
    this.barcode,
  });

  @override
  List<Object?> get props => [name, price, category, sortOrder, barcode];
}

class CreateMenuItemsBulk extends MenuEvent {
  final List<Map<String, dynamic>> items;
  const CreateMenuItemsBulk({required this.items});
  @override
  List<Object?> get props => [items];
}

class CreateRetailProductsBulk extends MenuEvent {
  final List<Map<String, dynamic>> items;
  const CreateRetailProductsBulk({required this.items});
  @override
  List<Object?> get props => [items];
}

class DeleteMenuItem extends MenuEvent {
  final int id;
  final String mode;
  const DeleteMenuItem(this.id, {this.mode = 'auto'});
  @override
  List<Object?> get props => [id, mode];
}

class DeleteMenuItemsBulk extends MenuEvent {
  final List<int> ids;
  final String mode;
  const DeleteMenuItemsBulk(this.ids, {this.mode = 'auto'});
  @override
  List<Object?> get props => [ids, mode];
}

class DeleteMenuItemWithPolicy extends MenuEvent {
  final int id;
  final String policy;
  const DeleteMenuItemWithPolicy(this.id, {required this.policy});
  @override
  List<Object?> get props => [id, policy];
}

class MergeMenuItems extends MenuEvent {
  final int targetItemId;
  final List<int> sourceItemIds;
  final String? targetName;

  const MergeMenuItems({
    required this.targetItemId,
    required this.sourceItemIds,
    this.targetName,
  });

  @override
  List<Object?> get props => [targetItemId, sourceItemIds, targetName];
}

class ExtractVariation extends MenuEvent {
  final int childId;
  const ExtractVariation(this.childId);
  @override
  List<Object?> get props => [childId];
}

class UnbundleMenuItem extends MenuEvent {
  final int itemId;
  const UnbundleMenuItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class UpdateMenuItem extends MenuEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateMenuItem(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class UpdateRetailProduct extends MenuEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateRetailProduct(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class CreateRetailProduct extends MenuEvent {
  final String name;
  final int? categoryId;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final Map<String, dynamic>? attributes;
  final double initialStock;
  final double minStockAlert;
  final int sortOrder;
  final String? barcode;
  final int? parentId;

  const CreateRetailProduct({
    required this.name,
    this.categoryId,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    this.attributes,
    this.initialStock = 0.0,
    this.minStockAlert = 0.0,
    this.sortOrder = 0,
    this.barcode,
    this.parentId,
  });

  @override
  List<Object?> get props => [
        name,
        categoryId,
        unit,
        purchasePrice,
        sellingPrice,
        attributes,
        initialStock,
        minStockAlert,
        sortOrder,
        barcode,
        parentId,
      ];
}

class CreateRetailProductGroup extends MenuEvent {
  final String name;
  final int? categoryId;
  final String? flavor;
  final List<Map<String, dynamic>> variations;

  const CreateRetailProductGroup({
    required this.name,
    this.categoryId,
    this.flavor,
    required this.variations,
  });

  @override
  List<Object?> get props => [name, categoryId, flavor, variations];
}
