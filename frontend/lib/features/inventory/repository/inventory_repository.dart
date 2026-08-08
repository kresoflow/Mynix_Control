import 'package:dio/dio.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';

part 'parts/suppliers_part.dart';
part 'parts/recipes_part.dart';
part 'parts/ingredients_part.dart';
part 'parts/documents_part.dart';
part 'parts/categories_part.dart';

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

  Future<int> createIngredient({
    required String name,
    required String unit,
    required double minStockAlert,
    required double costPerUnit,
    int? categoryId,
    double initialStock = 0.0,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _dio.post(
        '/ingredients/',
        data: {
          'name': name,
          'unit': unit,
          'min_stock_alert': minStockAlert,
          'cost_per_unit': costPerUnit,
          'initial_stock': initialStock,
          'sort_order': sortOrder,
          'category_id': categoryId,
        },
      );
      return response.data['id'] as int;
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

  Future<void> createCategoriesBulk(List<Map<String, dynamic>> categories) async {
    try {
      await _dio.post(
        '/categories/bulk',
        data: categories,
      );
    } catch (e) {
      throw Exception('Failed to bulk create categories: ${e.toString()}');
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
          currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0.0,
          minStockAlert: (json['min_stock_alert'] as num?)?.toDouble() ?? 0.0,
          costPerUnit: (json['cost'] as num?)?.toDouble() ?? 0.0,
          isLowStock: json['is_low_stock'] ?? false,
          price: (json['price'] as num?)?.toDouble(),
          attributes: {...?json['attributes'], 'is_retail': true},
          categoryId: json['category_id'],
          categoryName: json['category_name'],
          barcode: json['barcode'],
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
        data: {'name': name, if (contactInfo != null) 'contact_info': contactInfo},
      );
      return Supplier.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create supplier: ${e.toString()}');
    }
  }

  Future<Supplier> updateSupplier(int id, {required String name, String? contactInfo, bool? isActive}) async {
    try {
      final response = await _dio.put(
        '/suppliers/$id',
        data: {
          'name': name,
          if (contactInfo != null) 'contact_info': contactInfo,
          if (isActive != null) 'is_active': isActive,
        },
      );
      return Supplier.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update supplier: ${e.toString()}');
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _dio.delete('/suppliers/$id');
    } catch (e) {
      throw Exception('Failed to delete supplier: ${e.toString()}');
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
