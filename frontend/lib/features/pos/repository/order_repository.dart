import 'package:dio/dio.dart';
import 'package:retail_os_frontend/features/pos/models/cart_item.dart';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<void> submitOrder(List<CartItem> items, String paymentMethod) async {
    final orderData = {
      'payment_method': paymentMethod.toLowerCase(),
      'items': items.map((item) => {
        'menu_item_id': item.menuItem.id,
        'quantity': item.quantity,
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
