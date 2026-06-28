import 'package:dio/dio.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';
import 'package:retail_os_frontend/features/pos/models/menu_category.dart';
import 'package:retail_os_frontend/features/inventory/models/document.dart';
import 'package:retail_os_frontend/features/inventory/models/supplier.dart';

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
    int? categoryId,
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
          if (categoryId != null) 'category_id': categoryId,
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

  Future<void> bulkUpdateRecipe(int menuItemId, List<Map<String, dynamic>> recipes) async {
    try {
      await _dio.put(
        '/menu/$menuItemId/recipe',
        data: {'recipes': recipes},
      );
    } catch (e) {
      throw Exception('Failed to bulk update recipe: ${e.toString()}');
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

  Future<void> deleteIngredient(int id) async {
    try {
      await _dio.delete('/ingredients/$id');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(
          e.response?.data['detail'] ?? 'Failed to delete ingredient',
        );
      }
      throw Exception('Failed to delete ingredient: ${e.toString()}');
    }
  }

  // --- Suppliers ---
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _dio.get('/suppliers/');
      final data = response.data as List;
      return data.map((json) => Supplier.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load suppliers: ${e.toString()}');
    }
  }

  Future<Supplier> createSupplier(String name, {String? contactInfo}) async {
    try {
      final response = await _dio.post(
        '/suppliers/',
        data: {
          'name': name,
          if (contactInfo != null) 'contact_info': contactInfo,
        },
      );
      return Supplier.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create supplier: ${e.toString()}');
    }
  }

  // --- Documents ---
  Future<List<InventoryDocument>> getDocuments({String? type}) async {
    try {
      final response = await _dio.get('/documents/', queryParameters: {
        if (type != null) 'type': type,
      });
      final data = response.data as List;
      return data.map((json) => InventoryDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load documents: ${e.toString()}');
    }
  }

  Future<InventoryDocument> getDocument(int id) async {
    try {
      final response = await _dio.get('/documents/$id');
      return InventoryDocument.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load document details: ${e.toString()}');
    }
  }

  Future<InventoryDocument> createDocument(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/documents/', data: data);
      return InventoryDocument.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to create document');
      }
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  Future<InventoryDocument> completeDocument(int id) async {
    try {
      final response = await _dio.post('/documents/$id/complete');
      return InventoryDocument.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to complete document');
      }
      throw Exception('Failed to complete document: ${e.toString()}');
    }
  }
}
