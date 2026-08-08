
import 'package:dio/dio.dart';
import '../models/pos_order.dart';

class OrdersRepository {
  final Dio dio;

  OrdersRepository({required this.dio});

  Future<List<PosOrder>> fetchOrders() async {
    final response = await dio.get('/orders/');
    final List<dynamic> data = response.data;
    return data.map((e) => PosOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelOrder(int orderId) async {
    await dio.patch(
      '/orders/$orderId/status',
      queryParameters: {'new_status': 'cancelled'},
    );
  }
}
