import 'package:dio/dio.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';
import 'package:retail_os_frontend/features/pos/models/menu_category.dart';

class InventoryRepository {
  final Dio _dio;

  InventoryRepository(this._dio);

  Future<List<Ingredient>> getIngredients() async {
    try {
      final response = await _dio.get('/ingredients/');
      final data = response.data as List;
      return data.map((json) => Ingredient.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load ingredients: ${e.toString()}');
    }
  }

  Future<void> createIngredient({
    required String name,
    required String unit,
    required double minStockAlert,
    required double costPerUnit,
    double initialStock = 0.0,
    int sortOrder = 0,
  }) async {
    try {
      await _dio.post(
        '/ingredients/',
        data: {
          'name': name,
          'unit': unit,
          'min_stock_alert': minStockAlert,
          'cost_per_unit': costPerUnit,
          'initial_stock': initialStock,
          'sort_order': sortOrder,
        },
      );
    } catch (e) {
      throw Exception('Failed to create ingredient: ${e.toString()}');
    }
  }

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
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (sortOrder != null) data['sort_order'] = sortOrder;
      if (color != null) data['color'] = color;
      if (isVisible != null) data['is_visible'] = isVisible;
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

  Future<List<Map<String, dynamic>>> getRecipe(int menuItemId) async {
    try {
      final response = await _dio.get('/menu/$menuItemId/recipe');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load recipe: ${e.toString()}');
    }
  }

  Future<void> addIngredientToRecipe(
    int menuItemId,
    int ingredientId,
    double quantity,
  ) async {
    try {
      await _dio.post(
        '/menu/$menuItemId/recipe',
        data: {'ingredient_id': ingredientId, 'quantity_required': quantity},
      );
    } catch (e) {
      throw Exception('Failed to add ingredient to recipe: ${e.toString()}');
    }
  }

  Future<void> removeIngredientFromRecipe(
    int menuItemId,
    int ingredientId,
  ) async {
    try {
      await _dio.delete('/menu/$menuItemId/recipe/$ingredientId');
    } catch (e) {
      throw Exception(
        'Failed to remove ingredient from recipe: ${e.toString()}',
      );
    }
  }

  Future<void> receiveStock(
    int ingredientId,
    double quantity,
    String reason, {
    bool isRetail = false,
  }) async {
    try {
      if (isRetail) {
        await _dio.post(
          '/inventory/retail/receive',
          data: {
            'retail_product_id': ingredientId,
            'quantity': quantity,
            'reason': reason,
          },
        );
      } else {
        await _dio.post(
          '/ingredients/receive',
          data: {
            'ingredient_id': ingredientId,
            'quantity': quantity,
            'reason': reason,
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to receive stock: ${e.toString()}');
    }
  }

  Future<List<Ingredient>> getRetailProducts() async {
    try {
      final response = await _dio.get('/inventory/retail/');
      final data = response.data as List;
      return data.map((json) {
        return Ingredient(
          id: json['id'],
          name: json['name'],
          unit: json['unit'],
          currentStock: (json['current_stock'] as num).toDouble(),
          minStockAlert: (json['min_stock_alert'] as num).toDouble(),
          costPerUnit: (json['cost'] as num).toDouble(),
          isLowStock: json['is_low_stock'] ?? false,
          price: (json['price'] as num?)?.toDouble(),
          attributes: {...?json['attributes'], 'is_retail': true},
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load retail products: ${e.toString()}');
    }
  }

  Future<void> updateIngredient(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/ingredients/$id', data: data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(
          e.response?.data['detail'] ?? 'Failed to update ingredient',
        );
      }
      throw Exception('Failed to update ingredient: ${e.toString()}');
    }
  }
}
