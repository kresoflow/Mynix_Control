import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/offline_order_payload.dart';

class LocalPosClient {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  /// Pings the Cashier PC over local LAN Wi-Fi
  static Future<bool> ping(String masterIp, {int port = 8080}) async {
    try {
      final res = await _dio.get('http://$masterIp:$port/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends order directly to Cashier PC over local LAN Wi-Fi
  static Future<bool> sendOrderToMaster(
    String masterIp,
    OfflineOrderPayload order, {
    int port = 8080,
  }) async {
    try {
      final res = await _dio.post(
        'http://$masterIp:$port/api/local/order',
        data: jsonEncode(order.toJson()),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
