
import 'package:dio/dio.dart';
import '../models/pos_order.dart';

class OrdersRepository {
  final Dio dio;

  OrdersRepository({required this.dio});

  Future<List<PosOrder>> fetchOrders({String? startDate, String? endDate}) async {
    final Map<String, dynamic> params = {};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final response = await dio.get('/orders/', queryParameters: params);
    final List<dynamic> data = response.data;
    return data.map((e) => PosOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelOrder(int orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    await dio.patch(
      '/orders/$orderId/status',
      queryParameters: {'new_status': newStatus},
    );
  }
}
