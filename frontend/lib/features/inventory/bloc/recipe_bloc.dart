// ==============================================================================
// БЛОК: Технологические карты и рецептуры (RecipeBloc)
// ДОМЕН: lib/features/inventory/bloc/recipe_bloc.dart
// ==============================================================================
//
// [ИНВАРИАНТ] Бесшовный Optimistic UI: операции изменения расхода, добавления
// и удаления сырья применяются в памяти мгновенно (0 мс), не сбрасывая
// дерево виджетов в RecipeLoading и сохраняя скролл и фокус пользователя.
//
// ==============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'recipe_event.dart';
import 'recipe_state.dart';

export 'recipe_state.dart';

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

  bool _isLoadingSummary = false;

  Map<int, Map<String, dynamic>> _recalculateSummary({
    required Map<int, Map<String, dynamic>> currentSummary,
    required int menuItemId,
    required List<Map<String, dynamic>> recipes,
  }) {
    final updated = Map<int, Map<String, dynamic>>.from(currentSummary);
    final double totalCost = recipes.fold(0.0, (sum, r) {
      final q = (r['quantity_required'] as num?)?.toDouble() ?? 0.0;
      final c = (r['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
      return sum + (q * c);
    });
    updated[menuItemId] = {
      'menu_item_id': menuItemId,
      'ingredients_count': recipes.length,
      'total_cost': totalCost,
      'has_recipe': recipes.isNotEmpty,
    };
    return updated;
  }

  Future<void> _onLoadRecipesSummary(
    LoadRecipesSummary event,
    Emitter<RecipeState> emit,
  ) async {
    if (_isLoadingSummary) return;
    _isLoadingSummary = true;
    try {
      final summaryList = await repository.getRecipesSummary();
      final Map<int, Map<String, dynamic>> summaryMap = {
        for (var item in summaryList) item['menu_item_id'] as int: item,
      };
      if (state is RecipeLoaded) {
        final current = state as RecipeLoaded;
        emit(
          RecipeLoaded(
            menuItemId: current.menuItemId,
            recipes: current.recipes,
            recipesSummary: summaryMap,
          ),
        );
      } else {
        emit(
          RecipeLoaded(
            menuItemId: null,
            recipes: const [],
            recipesSummary: summaryMap,
          ),
        );
      }
    } catch (_) {
      // Сохраняем текущее состояние при временной ошибке сводки
    } finally {
      _isLoadingSummary = false;
    }
  }

  Future<void> _onLoadRecipe(
    LoadRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    if (!event.forceRefresh && state is RecipeLoaded) {
      final loaded = state as RecipeLoaded;
      if (loaded.menuItemId == event.menuItemId) {
        return;
      }
    }

    // Показывать лоадер только при первом открытии блюда или смене позиции
    final isSwitchingDish = state is! RecipeLoaded || (state as RecipeLoaded).menuItemId != event.menuItemId;
    if (isSwitchingDish) {
      emit(RecipeLoading(recipesSummary: state.recipesSummary));
    }

    try {
      final data = await repository.getRecipe(event.menuItemId);
      final updatedSummary = _recalculateSummary(
        currentSummary: state.recipesSummary,
        menuItemId: event.menuItemId,
        recipes: data,
      );
      emit(
        RecipeLoaded(
          menuItemId: event.menuItemId,
          recipes: data,
          recipesSummary: updatedSummary,
        ),
      );
    } catch (e) {
      if (isSwitchingDish) {
        emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
      }
    }
  }

  Future<void> _onUpdateQuantity(
    UpdateIngredientQuantityInRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    final previousState = state;
    if (state is RecipeLoaded && (state as RecipeLoaded).menuItemId == event.menuItemId) {
      final current = state as RecipeLoaded;
      final updatedRecipes = current.recipes.map((r) {
        if (r['ingredient_id'] == event.ingredientId) {
          return Map<String, dynamic>.from(r)..['quantity_required'] = event.quantity;
        }
        return Map<String, dynamic>.from(r);
      }).toList();

      final updatedSummary = _recalculateSummary(
        currentSummary: current.recipesSummary,
        menuItemId: event.menuItemId,
        recipes: updatedRecipes,
      );

      // [ИНВАРИАНТ] Мгновенное обновление UI (0 мс задержки)
      emit(
        RecipeLoaded(
          menuItemId: event.menuItemId,
          recipes: updatedRecipes,
          recipesSummary: updatedSummary,
        ),
      );
    }

    try {
      await repository.addIngredientToRecipe(
        event.menuItemId,
        event.ingredientId,
        event.quantity,
      );
    } catch (e) {
      // Откат при сетевом сбое
      emit(previousState);
    }
  }

  Future<void> _onRemoveIngredient(
    RemoveIngredientFromRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    final previousState = state;
    if (state is RecipeLoaded && (state as RecipeLoaded).menuItemId == event.menuItemId) {
      final current = state as RecipeLoaded;
      final updatedRecipes = current.recipes
          .where((r) => r['ingredient_id'] != event.ingredientId)
          .map((r) => Map<String, dynamic>.from(r))
          .toList();

      final updatedSummary = _recalculateSummary(
        currentSummary: current.recipesSummary,
        menuItemId: event.menuItemId,
        recipes: updatedRecipes,
      );

      // [ИНВАРИАНТ] Мгновенное удаление строки из UI (0 мс задержки)
      emit(
        RecipeLoaded(
          menuItemId: event.menuItemId,
          recipes: updatedRecipes,
          recipesSummary: updatedSummary,
        ),
      );
    }

    try {
      await repository.removeIngredientFromRecipe(
        event.menuItemId,
        event.ingredientId,
      );
    } catch (e) {
      // Откат при сетевом сбое
      emit(previousState);
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
      // Бесшовная загрузка обновленной техкарты без RecipeLoading
      final data = await repository.getRecipe(event.menuItemId);
      final updatedSummary = _recalculateSummary(
        currentSummary: state.recipesSummary,
        menuItemId: event.menuItemId,
        recipes: data,
      );
      emit(
        RecipeLoaded(
          menuItemId: event.menuItemId,
          recipes: data,
          recipesSummary: updatedSummary,
        ),
      );
    } catch (e) {
      if (state is! RecipeLoaded) {
        emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
      }
    }
  }

  Future<void> _onSaveBulkRecipe(
    SaveBulkRecipe event,
    Emitter<RecipeState> emit,
  ) async {
    try {
      await repository.bulkUpdateRecipe(event.menuItemId, event.recipes);
      final data = await repository.getRecipe(event.menuItemId);
      final updatedSummary = _recalculateSummary(
        currentSummary: state.recipesSummary,
        menuItemId: event.menuItemId,
        recipes: data,
      );
      emit(
        RecipeLoaded(
          menuItemId: event.menuItemId,
          recipes: data,
          recipesSummary: updatedSummary,
        ),
      );
    } catch (e) {
      if (state is! RecipeLoaded) {
        emit(RecipeError(message: e.toString(), recipesSummary: state.recipesSummary));
      }
    }
  }
}
