import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'pos_outbox_service.dart';

class PosSyncService {
  final ApiClient apiClient;
  Timer? _timer;
  bool _isDisposed = false;

  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastSyncError = ValueNotifier<String?>(null);

  PosSyncService({required this.apiClient});

  void start() {
    _timer?.cancel();
    // Check outbox periodically (every 15 seconds), zero traffic if outbox is empty
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isDisposed && PosOutboxService.pendingCount > 0 && !isSyncing.value) {
        syncPendingOrders();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _isDisposed = true;
  }

  /// Triggers full FIFO synchronization of all pending offline orders to backend
  Future<int> syncPendingOrders() async {
    if (isSyncing.value) return 0;

    final pending = PosOutboxService.getPendingOrders();
    if (pending.isEmpty) {
      lastSyncError.value = null;
      return 0;
    }

    isSyncing.value = true;
    lastSyncError.value = null;
    int syncedCount = 0;

    try {
      for (var order in pending) {
        try {
          final payload = {
            'client_uuid': order.clientUuid,
            'items': order.items.map((it) => {
              'menu_item_id': it['menu_item_id'],
              'quantity': it['quantity'],
              if (it['unit_price_override'] != null) 'unit_price_override': it['unit_price_override'],
              if (it['options_json'] != null) 'options_json': it['options_json'],
            }).toList(),
            'payment_method': order.paymentMethod,
            if (order.customerId != null) 'customer_id': order.customerId,
            'bonus_spent': order.bonusSpent,
            if (order.note != null && order.note!.isNotEmpty) 'note': order.note,
          };

          final response = await apiClient.dio.post('/orders/', data: payload);
          if (response.statusCode == 200 || response.statusCode == 201) {
            await PosOutboxService.removeOrder(order.clientUuid);
            syncedCount++;
          }
        } catch (e) {
          lastSyncError.value = e.toString();
          // Stop on first network error to preserve FIFO ordering
          break;
        }
      }
    } finally {
      isSyncing.value = false;
    }

    return syncedCount;
  }
}
