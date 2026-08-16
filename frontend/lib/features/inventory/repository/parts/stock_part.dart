part of '../inventory_repository.dart';

extension StockPart on InventoryRepository {
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

  Future<Map<String, dynamic>> checkAvailability(int menuItemId, {int quantity = 1}) async {
    try {
      final response = await _dio.get(
        '/menu/$menuItemId/availability',
        queryParameters: {'quantity': quantity},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to check availability: ${e.toString()}');
    }
  }
}
