import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/network/websocket_service.dart';

class KitchenRepository {
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

  /// Connect to WebSocket stream for realtime updates via singleton WebSocketService
  Stream<Map<String, dynamic>> connectToKitchenStream(String tenantId) {
    webSocketService.connect(tenantId);
    return webSocketService.messages;
  }

  void disconnect() {
    webSocketService.disconnect();
  }
}
