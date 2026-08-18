import 'package:equatable/equatable.dart';

abstract class IngredientEvent extends Equatable {
  const IngredientEvent();

  @override
  List<Object?> get props => [];
}

class LoadIngredients extends IngredientEvent {}

class CreateIngredient extends IngredientEvent {
  final String name;
  final String unit;
  final double minStockAlert;
  final double costPerUnit;
  final int? categoryId;

  final double initialStock;
  final int sortOrder;
  final String? barcode;

  const CreateIngredient({
    required this.name,
    required this.unit,
    required this.minStockAlert,
    required this.costPerUnit,
    this.categoryId,
    this.initialStock = 0.0,
    this.sortOrder = 0,
    this.barcode,
  });

  @override
  List<Object?> get props => [
    name,
    unit,
    minStockAlert,
    costPerUnit,
    categoryId,
    initialStock,
    sortOrder,
    barcode,
  ];
}

class CreateIngredientsBulk extends IngredientEvent {
  final List<Map<String, dynamic>> ingredients;

  const CreateIngredientsBulk({required this.ingredients});

  @override
  List<Object?> get props => [ingredients];
}

class ReceiveStock extends IngredientEvent {
  final int ingredientId;
  final double quantity;
  final String reason;
  final bool isRetail;

  const ReceiveStock({
    required this.ingredientId,
    required this.quantity,
    required this.reason,
    this.isRetail = false,
  });

  @override
  List<Object?> get props => [ingredientId, quantity, reason, isRetail];
}

class UpdateIngredient extends IngredientEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateIngredient(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteIngredient extends IngredientEvent {
  final int id;
  const DeleteIngredient(this.id);

  @override
  List<Object?> get props => [id];
}
