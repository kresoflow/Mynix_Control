import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:retail_os_frontend/features/inventory/repository/inventory_repository.dart';
import 'recipe_event.dart';

abstract class RecipeState extends Equatable {
  const RecipeState();
  @override
  List<Object?> get props => [];
}

class RecipeInitial extends RecipeState {}

class RecipeLoading extends RecipeState {}

class RecipeLoaded extends RecipeState {
  final int menuItemId;
  final List<Map<String, dynamic>> recipes;

  const RecipeLoaded({required this.menuItemId, required this.recipes});

  @override
  List<Object?> get props => [menuItemId, recipes];
}

class RecipeError extends RecipeState {
  final String message;
  const RecipeError({required this.message});

  @override
  List<Object?> get props => [message];
}

class RecipeBloc extends Bloc<RecipeEvent, RecipeState> {
  final InventoryRepository repository;

  RecipeBloc(this.repository) : super(RecipeInitial()) {
    on<LoadRecipe>(_onLoadRecipe);
    on<AddIngredientToRecipe>(_onAddIngredient);
    on<RemoveIngredientFromRecipe>(_onRemoveIngredient);
  }

  Future<void> _onLoadRecipe(
    LoadRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    emit(RecipeLoading());
    try {
      final data = await repository.getRecipe(event.menuItemId);
      emit(RecipeLoaded(menuItemId: event.menuItemId, recipes: data));
    } catch (e) {
      emit(RecipeError(message: e.toString()));
    }
  }

  Future<void> _onAddIngredient(
    AddIngredientToRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    try {
      await repository.addIngredientToRecipe(
        event.menuItemId,
        event.ingredientId,
        event.quantity,
      );
      add(LoadRecipe(event.menuItemId));
    } catch (e) {
      emit(RecipeError(message: e.toString()));
    }
  }

  Future<void> _onRemoveIngredient(
    RemoveIngredientFromRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    try {
      await repository.removeIngredientFromRecipe(
        event.menuItemId,
        event.ingredientId,
      );
      add(LoadRecipe(event.menuItemId));
    } catch (e) {
      emit(RecipeError(message: e.toString()));
    }
  }
}
