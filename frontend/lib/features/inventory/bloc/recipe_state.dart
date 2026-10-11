// ==============================================================================
// СОСТОЯНИЯ: Технологические карты и рецептуры (RecipeState)
// ДОМЕН: lib/features/inventory/bloc/recipe_state.dart
// ==============================================================================

import 'package:equatable/equatable.dart';

abstract class RecipeState extends Equatable {
  final Map<int, Map<String, dynamic>> recipesSummary;

  const RecipeState({this.recipesSummary = const {}});

  @override
  List<Object?> get props => [recipesSummary];
}

class RecipeInitial extends RecipeState {
  const RecipeInitial({super.recipesSummary});
}

class RecipeLoading extends RecipeState {
  const RecipeLoading({super.recipesSummary});
}

class RecipeLoaded extends RecipeState {
  final int? menuItemId;
  final List<Map<String, dynamic>> recipes;
  final String? errorMessage;

  const RecipeLoaded({
    this.menuItemId,
    this.recipes = const [],
    this.errorMessage,
    super.recipesSummary,
  });

  @override
  List<Object?> get props => [menuItemId, recipes, errorMessage, recipesSummary];
}

class RecipeError extends RecipeState {
  final String message;

  const RecipeError({required this.message, super.recipesSummary});

  @override
  List<Object?> get props => [message, recipesSummary];
}
