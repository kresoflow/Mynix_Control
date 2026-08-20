import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_order_payload.dart';

class PosOutboxService {
  static const String outboxBoxName = 'pos_outbox';
  static const String shiftStateBoxName = 'pos_shift_state';

  static Box? _outbox;
  static Box? _shiftBox;

  static Future<void> init() async {
    if (!Hive.isBoxOpen(outboxBoxName)) {
      _outbox = await Hive.openBox(outboxBoxName);
    } else {
      _outbox = Hive.box(outboxBoxName);
    }

    if (!Hive.isBoxOpen(shiftStateBoxName)) {
      _shiftBox = await Hive.openBox(shiftStateBoxName);
    } else {
      _shiftBox = Hive.box(shiftStateBoxName);
    }
  }

  static Box get outbox {
    if (_outbox == null || !_outbox!.isOpen) {
      _outbox = Hive.box(outboxBoxName);
    }
    return _outbox!;
  }

  static Box get shiftBox {
    if (_shiftBox == null || !_shiftBox!.isOpen) {
      _shiftBox = Hive.box(shiftStateBoxName);
    }
    return _shiftBox!;
  }

  /// Listenable for reactive UI widgets
  static ValueListenable<Box> listenable() {
    return outbox.listenable();
  }

  /// Save offline order to Outbox
  static Future<void> saveOrder(OfflineOrderPayload order) async {
    await outbox.put(order.clientUuid, order.toJson());
  }

  /// Get all pending orders sorted by creation time (FIFO)
  static List<OfflineOrderPayload> getPendingOrders() {
    final List<OfflineOrderPayload> result = [];
    for (var key in outbox.keys) {
      final data = outbox.get(key);
      if (data != null && data is Map) {
        try {
          final payload = OfflineOrderPayload.fromJson(Map<String, dynamic>.from(data));
          result.add(payload);
        } catch (_) {}
      }
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  /// Number of pending orders
  static int get pendingCount => outbox.length;

  /// Sum of all pending orders
  static double get pendingTotalAmount {
    double total = 0.0;
    for (var order in getPendingOrders()) {
      total += order.totalAmount;
    }
    return total;
  }

  /// Remove synced order from Outbox
  static Future<void> removeOrder(String clientUuid) async {
    await outbox.delete(clientUuid);
  }

  /// Get sequential local order number for the current shift
  static int getNextLocalOrderNumber() {
    final current = (shiftBox.get('daily_order_counter') as num?)?.toInt() ?? 0;
    final next = current + 1;
    shiftBox.put('daily_order_counter', next);
    return next;
  }

  /// Reset local order counter (when new shift is opened)
  static void resetLocalOrderCounter() {
    shiftBox.put('daily_order_counter', 0);
  }
}
