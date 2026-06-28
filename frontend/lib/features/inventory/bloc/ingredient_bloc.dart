import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';
import 'package:retail_os_frontend/features/inventory/repository/inventory_repository.dart';
import 'ingredient_event.dart';

abstract class IngredientState extends Equatable {
  const IngredientState();
  @override
  List<Object?> get props => [];
}

class IngredientLoading extends IngredientState {}

class IngredientLoaded extends IngredientState {
  final List<Ingredient> ingredients;
  const IngredientLoaded({required this.ingredients});

  @override
  List<Object?> get props => [ingredients];
}

class IngredientError extends IngredientState {
  final String message;
  const IngredientError({required this.message});

  @override
  List<Object?> get props => [message];
}

class IngredientBloc extends Bloc<IngredientEvent, IngredientState> {
  final InventoryRepository repository;

  IngredientBloc(this.repository) : super(IngredientLoading()) {
    on<LoadIngredients>(_onLoadIngredients);
    on<CreateIngredient>(_onCreateIngredient);
    on<ReceiveStock>(_onReceiveStock);
    on<UpdateIngredient>(_onUpdateIngredient);
    on<DeleteIngredient>(_onDeleteIngredient);
  }

  Future<void> _onLoadIngredients(
    LoadIngredients event,
    Emitter<IngredientState> emit,
  ) async {
    emit(IngredientLoading());
    try {
      final rawItems = await repository.getIngredients();
      final retailItems = await repository.getRetailProducts();
      final merged = [...rawItems, ...retailItems];
      emit(IngredientLoaded(ingredients: merged));
    } catch (e) {
      emit(IngredientError(message: e.toString()));
    }
  }

  Future<void> _onCreateIngredient(
    CreateIngredient event,
    Emitter<IngredientState> emit,
  ) async {
    try {
      await repository.createIngredient(
        name: event.name,
        unit: event.unit,
        minStockAlert: event.minStockAlert,
        costPerUnit: event.costPerUnit,
        categoryId: event.categoryId,
        initialStock: event.initialStock,
        sortOrder: event.sortOrder,
      );
      add(LoadIngredients());
    } catch (e) {
      emit(IngredientError(message: e.toString()));
      add(LoadIngredients());
    }
  }

  Future<void> _onReceiveStock(
    ReceiveStock event,
    Emitter<IngredientState> emit,
  ) async {
    try {
      await repository.receiveStock(
        event.ingredientId,
        event.quantity,
        event.reason,
        isRetail: event.isRetail,
      );
      add(LoadIngredients());
    } catch (e) {
      emit(IngredientError(message: e.toString()));
      add(LoadIngredients());
    }
  }

  Future<void> _onUpdateIngredient(
    UpdateIngredient event,
    Emitter<IngredientState> emit,
  ) async {
    try {
      await repository.updateIngredient(event.id, event.data);
      add(LoadIngredients());
    } catch (e) {
      emit(IngredientError(message: e.toString()));
      add(LoadIngredients());
    }
  }

  Future<void> _onDeleteIngredient(
    DeleteIngredient event,
    Emitter<IngredientState> emit,
  ) async {
    try {
      await repository.deleteIngredient(event.id);
      add(LoadIngredients());
    } catch (e) {
      emit(IngredientError(message: e.toString()));
      add(LoadIngredients());
    }
  }
}
