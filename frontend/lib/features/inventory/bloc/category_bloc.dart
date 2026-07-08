import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'category_event.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<MenuCategory> categories;
  const CategoryLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final InventoryRepository repository;

  CategoryBloc(this.repository) : super(CategoryLoading()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategory>(_onCreateCategory);
    on<CreateCategoriesBulk>(_onCreateCategoriesBulk);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onCreateCategoriesBulk(
    CreateCategoriesBulk event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.createCategoriesBulk(event.categories);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
      add(LoadCategories());
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final items = await repository.getCategories();
      emit(CategoryLoaded(categories: items));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.createCategory(
        name: event.name,
        categoryType: event.categoryType,
        sortOrder: event.sortOrder,
        color: event.color,
        parentId: event.parentId,
        isVisible: event.isVisible,
        icon: event.icon,
      );
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
      add(LoadCategories());
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.updateCategory(
        id: event.id,
        name: event.name,
        sortOrder: event.sortOrder,
        color: event.color,
        isVisible: event.isVisible,
        icon: event.icon,
      );
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
      add(LoadCategories());
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.deleteCategory(event.id, mode: event.mode);
      add(LoadCategories());
    } catch (e) {
      // Re-emit loaded but we need a way to show toast. For now just emit error.
      emit(
        CategoryError(message: e.toString().replaceFirst('Exception: ', '')),
      );
      add(LoadCategories());
    }
  }
}
