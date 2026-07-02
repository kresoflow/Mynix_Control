part of '../inventory_repository.dart';

extension IngredientsPart on InventoryRepository {
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
          if (categoryId != null) 'category_id': categoryId,
        },
      );
      return response.data['id'] as int;
    } catch (e) {
      throw Exception('Failed to create ingredient: ${e.toString()}');
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
}
