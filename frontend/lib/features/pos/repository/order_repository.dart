import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mynix_frontend/core/utils/uuid_helper.dart';
import 'package:mynix_frontend/features/pos/models/cart_item.dart';
import 'package:mynix_frontend/features/pos/models/offline_order_payload.dart';
import 'package:mynix_frontend/features/pos/services/pos_outbox_service.dart';
import 'package:mynix_frontend/features/pos/services/lan/local_pos_client.dart';
import 'package:mynix_frontend/features/settings/services/lan_settings_service.dart';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<void> submitOrder(
    List<CartItem> items,
    String paymentMethod, {
    int? customerId,
    double? bonusSpent,
    String? note,
    String? tableNumber,
    String? orderSource,
  }) async {
    final clientUuid = UuidHelper.generate();

    final orderItemsList = items.map((item) {
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
        'menu_item_name': item.menuItem.name,
        'quantity': item.quantity,
        'unit_price_override': item.menuItem.price + item.selectedOptionsPrice,
        if (item.selectedOptionsJson != null) 'options_json': item.selectedOptionsJson,
      };
    }).toList();

    double totalAmount = 0.0;
    for (var item in items) {
      totalAmount += (item.menuItem.price + item.selectedOptionsPrice) * item.quantity;
    }
    if (bonusSpent != null && bonusSpent > 0) {
      totalAmount = (totalAmount - bonusSpent).clamp(0.0, double.infinity);
    }

    final orderData = {
      'client_uuid': clientUuid,
      'payment_method': paymentMethod.toLowerCase(),
      if (customerId != null) 'customer_id': customerId,
      if (bonusSpent != null && bonusSpent > 0) 'bonus_spent': bonusSpent,
      if (note != null && note.isNotEmpty) 'note': note,
      if (tableNumber != null && tableNumber.isNotEmpty) 'table_number': tableNumber,
      if (orderSource != null && orderSource.isNotEmpty) 'order_source': orderSource,
      'items': orderItemsList,
    };

    try {
      await _dio.post('/orders/', data: orderData);
    } on DioException catch (e) {
      final isNetworkFailure = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.response == null;

      if (isNetworkFailure) {
        await _handleOfflineOrderFallback(
          clientUuid: clientUuid,
          orderItemsList: orderItemsList,
          paymentMethod: paymentMethod,
          totalAmount: totalAmount,
          customerId: customerId,
          bonusSpent: bonusSpent,
          note: note,
        );
        return;
      }

      final errorData = e.response?.data;
      String errorMsg = 'Ошибка при создании заказа';
      if (errorData is Map && errorData['detail'] != null) {
        errorMsg = errorData['detail'].toString();
      } else if (errorData != null) {
        errorMsg = errorData.toString();
      }
      throw Exception(errorMsg);
    } catch (_) {
      await _handleOfflineOrderFallback(
        clientUuid: clientUuid,
        orderItemsList: orderItemsList,
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
        customerId: customerId,
        bonusSpent: bonusSpent,
        note: note,
      );
    }
  }

  /// Fetches incoming orders waiting for cashier approval
  Future<List<Map<String, dynamic>>> fetchPendingOrders() async {
    try {
      final response = await _dio.get('/orders/', queryParameters: {'status': 'pending_approval'});
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Не удалось загрузить входящие заказы: $e');
    }
  }

  /// Approves incoming hall order -> triggers stock deduction and sends to KDS
  Future<Map<String, dynamic>> approveOrder(
    int orderId, {
    String? paymentMethod,
    bool isPaid = false,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/approve',
        data: {
          if (paymentMethod != null) 'payment_method': paymentMethod,
          'is_paid': isPaid,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Ошибка при подтверждении заказа: $e');
    }
  }

  /// Rejects incoming hall order without stock deduction
  Future<Map<String, dynamic>> rejectOrder(int orderId, {String? reason}) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/reject',
        data: {if (reason != null) 'reason': reason},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Ошибка при отклонении заказа: $e');
    }
  }

  Future<void> _handleOfflineOrderFallback({
    required String clientUuid,
    required List<Map<String, dynamic>> orderItemsList,
    required String paymentMethod,
    required double totalAmount,
    int? customerId,
    double? bonusSpent,
    String? note,
  }) async {
    final localOrderNumber = PosOutboxService.getNextLocalOrderNumber();
    final offlinePayload = OfflineOrderPayload(
      clientUuid: clientUuid,
      orderNumber: localOrderNumber,
      items: orderItemsList,
      paymentMethod: paymentMethod.toLowerCase(),
      totalAmount: totalAmount,
      customerId: customerId,
      bonusSpent: bonusSpent ?? 0.0,
      note: note,
      createdAt: DateTime.now(),
    );

    final lan = LanSettingsService.current;
    if (lan.isClient && lan.masterIp.isNotEmpty) {
      final sentToMaster = await LocalPosClient.sendOrderToMaster(
        lan.masterIp,
        offlinePayload,
        port: lan.port,
      );
      if (sentToMaster) return;
    }

    if (!lan.isOfflineStorageEnabled) {
      throw Exception(
        'Офлайн-режим отключен. Для проведения оплаты требуется активное подключение к интернету.',
      );
    }

    await PosOutboxService.saveOrder(offlinePayload);
  }
}
