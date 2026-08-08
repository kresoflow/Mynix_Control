import 'package:dio/dio.dart';
import 'package:mynix_frontend/features/pos/models/cart_item.dart';

import 'dart:convert';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<void> submitOrder(List<CartItem> items, String paymentMethod) async {
    final orderData = {
      'payment_method': paymentMethod.toLowerCase(),
      'items': items.map((item) {
        int menuItemId = item.menuItem.id;
        if (item.selectedOptionsJson != null) {
          try {
            final parsed = jsonDecode(item.selectedOptionsJson!);
            if (parsed['child_item_id'] != null) {
              menuItemId = parsed['child_item_id'] as int;
            }
          } catch (_) {}
        }
        
        return {
          'menu_item_id': menuItemId,
          'quantity': item.quantity,
          'unit_price_override': item.menuItem.price + item.selectedOptionsPrice,
          if (item.selectedOptionsJson != null) 'options_json': item.selectedOptionsJson,
        };
      }).toList(),
    };

    try {
      await _dio.post('/orders/', data: orderData);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      throw Exception('Failed to submit order (422):\nPayload: $orderData\nError: $errorData');
    } catch (e) {
      throw Exception('Failed to submit order: ${e.toString()}');
    }
  }
}
