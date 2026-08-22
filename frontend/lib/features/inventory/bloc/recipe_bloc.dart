import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'recipe_event.dart';

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

  const RecipeLoaded({
    this.menuItemId,
    this.recipes = const [],
    super.recipesSummary,
  });

  @override
  List<Object?> get props => [menuItemId, recipes, recipesSummary];
}

class RecipeError extends RecipeState {
  final String message;

  const RecipeError({required this.message, super.recipesSummary});

  @override
  List<Object?> get props => [message, recipesSummary];
}

class RecipeBloc extends Bloc<RecipeEvent, RecipeState> {
  final InventoryRepository repository;

  RecipeBloc(this.repository) : super(const RecipeInitial()) {
    on<LoadRecipesSummary>(_onLoadRecipesSummary);
    on<LoadRecipe>(_onLoadRecipe);
    on<AddIngredientToRecipe>(_onAddIngredient);
    on<RemoveIngredientFromRecipe>(_onRemoveIngredient);
    on<UpdateIngredientQuantityInRecipe>(_onUpdateQuantity);
    on<SaveBulkRecipe>(_onSaveBulkRecipe);
  }

  Future<void> _onLoadRecipesSummary(
    LoadRecipesSummary event,
    Emitter<RecipeState> emit,
  ) async {
    try {
      final summaryList = await repository.getRecipesSummary();
      final Map<int, Map<String, dynamic>> summaryMap = {
        for (var item in summaryList) item['menu_item_id'] as int: item,
      };
      if (state is RecipeLoaded) {
        final current = state as RecipeLoaded;
        emit(RecipeLoaded(
          menuItemId: current.menuItemId,
          recipes: current.recipes,
          recipesSummary: summaryMap,
        ));
      } else {
        emit(RecipeLoaded(
          menuItemId: null,
          recipes: const [],
          recipesSummary: summaryMap,
        ));
      }
    } catch (e) {
      // Keep existing state on error
    }
  }

  Future<void> _onLoadRecipe(
    LoadRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    emit(RecipeLoading(recipesSummary: state.recipesSummary));
    try {
      final data = await repository.getRecipe(event.menuItemId);
      emit(RecipeLoaded(
        menuItemId: event.menuItemId,
        recipes: data,
        recipesSummary: state.recipesSummary,
      ));
    } catch (e) {
      emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
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
      add(LoadRecipesSummary());
    } catch (e) {
      emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
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
      add(LoadRecipesSummary());
    } catch (e) {
      emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
    }
  }

  Future<void> _onUpdateQuantity(
    UpdateIngredientQuantityInRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    try {
      await repository.addIngredientToRecipe(
        event.menuItemId,
        event.ingredientId,
        event.quantity,
      );
      add(LoadRecipe(event.menuItemId));
      add(LoadRecipesSummary());
    } catch (e) {
      emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
    }
  }

  Future<void> _onSaveBulkRecipe(
    SaveBulkRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    try {
      await repository.bulkUpdateRecipe(event.menuItemId, event.recipes);
      add(LoadRecipe(event.menuItemId));
      add(LoadRecipesSummary());
    } catch (e) {
      emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
    }
  }
}
