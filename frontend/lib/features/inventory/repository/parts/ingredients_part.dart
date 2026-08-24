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
    String? barcode,
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
          if (barcode != null) 'barcode': barcode,
        },
      );
      return response.data['id'] as int;
    } catch (e) {
      throw Exception('Failed to create ingredient: ${e.toString()}');
    }
  }

  Future<void> createIngredientsBulk(List<Map<String, dynamic>> items) async {
    await Future.wait(items.map((item) => createIngredient(
      name: item['name'],
      unit: item['unit'],
      minStockAlert: item['min_stock_alert'],
      costPerUnit: item['cost_per_unit'],
      categoryId: item['category_id'],
      initialStock: item['initial_stock'] ?? 0.0,
      sortOrder: item['sort_order'] ?? 0,
      barcode: item['barcode'],
    )));
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
          barcode: json['barcode'],
          categoryId: json['category_id'],
          categoryName: json['category_name'],
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
