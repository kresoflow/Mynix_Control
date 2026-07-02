part of '../inventory_repository.dart';

extension CategoriesPart on InventoryRepository {
  Future<List<MenuCategory>> getCategories() async {
    try {
      final response = await _dio.get('/categories/');
      final data = response.data as List;
      return data.map((json) => MenuCategory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: ${e.toString()}');
    }
  }

  Future<void> createCategory({
    required String name,
    required String categoryType,
    required int sortOrder,
    String? color,
    int? parentId,
    bool isVisible = true,
    String? icon,
  }) async {
    try {
      await _dio.post(
        '/categories/',
        data: {
          'name': name,
          'category_type': categoryType,
          'sort_order': sortOrder,
          'color': color,
          'parent_id': parentId,
          'is_visible': isVisible,
          'icon': icon,
        },
      );
    } catch (e) {
      throw Exception('Failed to create category: ${e.toString()}');
    }
  }

  Future<void> updateCategory({
    required int id,
    String? name,
    int? sortOrder,
    String? color,
    bool? isVisible,
    String? icon,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (sortOrder != null) data['sort_order'] = sortOrder;
      if (color != null) data['color'] = color;
      if (isVisible != null) data['is_visible'] = isVisible;
      if (icon != null) data['icon'] = icon;
      await _dio.put('/categories/$id', data: data);
    } catch (e) {
      throw Exception('Failed to update category: ${e.toString()}');
    }
  }

  Future<void> deleteCategory(int id, {String mode = 'only'}) async {
    try {
      await _dio.delete('/categories/$id?mode=$mode');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(
          e.response?.data['detail'] ?? 'Failed to delete category',
        );
      }
      throw Exception('Failed to delete category: ${e.toString()}');
    }
  }
}
