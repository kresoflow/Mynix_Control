import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {}

class CreateCategory extends CategoryEvent {
  final String name;
  final String categoryType;
  final int sortOrder;
  final String? color;
  final int? parentId;
  final bool isVisible;

  const CreateCategory({
    required this.name,
    this.categoryType = 'dish',
    this.sortOrder = 0,
    this.color,
    this.parentId,
    this.isVisible = true,
  });

  @override
  List<Object?> get props => [
    name,
    categoryType,
    sortOrder,
    color,
    parentId,
    isVisible,
  ];
}

class UpdateCategory extends CategoryEvent {
  final int id;
  final String? name;
  final int? sortOrder;
  final String? color;
  final bool? isVisible;

  const UpdateCategory({
    required this.id,
    this.name,
    this.sortOrder,
    this.color,
    this.isVisible,
  });

  @override
  List<Object?> get props => [id, name, sortOrder, color, isVisible];
}

class DeleteCategory extends CategoryEvent {
  final int id;
  final String mode;
  const DeleteCategory(this.id, {this.mode = 'only'});

  @override
  List<Object?> get props => [id, mode];
}
