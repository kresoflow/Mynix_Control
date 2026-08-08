import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mynix_frontend/core/network/api_client.dart';

class KitchenRepository {
  WebSocketChannel? _channel;
  
  /// Get active orders (new and cooking)
  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    try {
      final response = await apiClient.dio.get('/kitchen/kds/active');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Failed to load active orders: $e');
    }
  }

  /// Mark order as ready
  Future<void> markOrderAsReady(int orderId) async {
    try {
      await apiClient.dio.post('/kitchen/kds/$orderId/ready');
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Connect to WebSocket stream for realtime updates
  Stream<Map<String, dynamic>> connectToKitchenStream(String tenantId) {
    final wsUrl = Uri.parse('wss://api.kresoflow.com/ws/kitchen/$tenantId');
    _channel = WebSocketChannel.connect(wsUrl);
    
    return _channel!.stream.map((message) {
      if (message == 'pong') return {'event': 'pong'};
      return jsonDecode(message as String) as Map<String, dynamic>;
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
