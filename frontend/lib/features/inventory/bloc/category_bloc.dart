import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'category_event.dart';
export 'category_event.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<MenuCategory> categories;
  final Map<int, MenuCategory> categoryMap;
  final Map<String, MenuCategory> categoryStringMap;

  CategoryLoaded({
    required this.categories,
    Map<int, MenuCategory>? categoryMap,
    Map<String, MenuCategory>? categoryStringMap,
  })  : categoryMap = categoryMap ?? {for (final c in categories) c.id: c},
        categoryStringMap = categoryStringMap ?? {for (final c in categories) c.id.toString(): c};

  /// [UI-KIT] Мгновенный поиск категории по ID за O(1)
  MenuCategory? getById(dynamic id) {
    if (id == null) return null;
    if (id is int) return categoryMap[id];
    return categoryStringMap[id.toString()];
  }

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
    on<RestoreCategory>(_onRestoreCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<DeleteCategoriesBulk>(_onDeleteCategoriesBulk);
  }

  Future<void> _onCreateCategoriesBulk(
    CreateCategoriesBulk event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.createCategoriesBulk(event.categories);
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
      add(const LoadCategories());
    }
  }

  Future<void> _onDeleteCategoriesBulk(
    DeleteCategoriesBulk event,
    Emitter<CategoryState> emit,
  ) async {
    final currentCategories = state is CategoryLoaded ? (state as CategoryLoaded).categories : <MenuCategory>[];
    try {
      await repository.deleteCategoriesBulk(event.ids, mode: event.mode);
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString().replaceFirst('Exception: ', '')));
      if (currentCategories.isNotEmpty) {
        emit(CategoryLoaded(categories: currentCategories));
      } else {
        add(const LoadCategories());
      }
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    if (state is! CategoryLoaded) {
      emit(CategoryLoading());
    }
    try {
      final items = await repository.getCategories();
      emit(CategoryLoaded(categories: items));
    } catch (e) {
      if (state is! CategoryLoaded) {
        emit(CategoryError(message: e.toString()));
      }
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
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
      add(const LoadCategories());
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
        resetColor: event.resetColor,
        isVisible: event.isVisible,
        isArchived: event.isArchived,
        icon: event.icon,
      );
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
      add(const LoadCategories());
    }
  }

  Future<void> _onRestoreCategory(
    RestoreCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await repository.restoreCategory(event.id);
      add(const LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
      add(const LoadCategories());
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final currentCategories = state is CategoryLoaded ? (state as CategoryLoaded).categories : <MenuCategory>[];
    try {
      await repository.deleteCategory(event.id, mode: event.mode);
      add(const LoadCategories());
    } catch (e) {
      emit(
        CategoryError(message: e.toString().replaceFirst('Exception: ', '')),
      );
      if (currentCategories.isNotEmpty) {
        emit(CategoryLoaded(categories: currentCategories));
      } else {
        add(const LoadCategories());
      }
    }
  }
}
