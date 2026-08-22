import 'package:equatable/equatable.dart';

abstract class RecipeEvent extends Equatable {
  const RecipeEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecipesSummary extends RecipeEvent {}

class LoadRecipe extends RecipeEvent {
  final int menuItemId;

  const LoadRecipe(this.menuItemId);

  @override
  List<Object?> get props => [menuItemId];
}

class AddIngredientToRecipe extends RecipeEvent {
  final int menuItemId;
  final int ingredientId;
  final double quantity;

  const AddIngredientToRecipe({
    required this.menuItemId,
    required this.ingredientId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [menuItemId, ingredientId, quantity];
}

class RemoveIngredientFromRecipe extends RecipeEvent {
  final int menuItemId;
  final int ingredientId;

  const RemoveIngredientFromRecipe({
    required this.menuItemId,
    required this.ingredientId,
  });

  @override
  List<Object?> get props => [menuItemId, ingredientId];
}

class UpdateIngredientQuantityInRecipe extends RecipeEvent {
  final int menuItemId;
  final int ingredientId;
  final double quantity;

  const UpdateIngredientQuantityInRecipe({
    required this.menuItemId,
    required this.ingredientId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [menuItemId, ingredientId, quantity];
}

class SaveBulkRecipe extends RecipeEvent {
  final int menuItemId;
  final List<Map<String, dynamic>> recipes;

  const SaveBulkRecipe({
    required this.menuItemId,
    required this.recipes,
  });

  @override
  List<Object?> get props => [menuItemId, recipes];
}
