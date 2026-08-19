import 'package:dio/dio.dart';
import 'package:mynix_frontend/features/pos/models/cart_item.dart';
import 'dart:convert';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<void> submitOrder(
    List<CartItem> items,
    String paymentMethod, {
    int? customerId,
    double? bonusSpent,
    String? note,
  }) async {
    final orderData = {
      'payment_method': paymentMethod.toLowerCase(),
      if (customerId != null) 'customer_id': customerId,
      if (bonusSpent != null && bonusSpent > 0) 'bonus_spent': bonusSpent,
      if (note != null && note.isNotEmpty) 'note': note,
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
      String errorMsg = 'Ошибка при создании заказа';
      if (errorData is Map && errorData['detail'] != null) {
        errorMsg = errorData['detail'].toString();
      } else if (errorData != null) {
        errorMsg = errorData.toString();
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Ошибка при создании заказа: $e');
    }
  }
}
