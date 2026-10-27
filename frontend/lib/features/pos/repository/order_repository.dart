import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kreso_frontend/core/utils/uuid_helper.dart';
import 'package:kreso_frontend/features/pos/models/cart_item.dart';
import 'package:kreso_frontend/features/pos/models/offline_order_payload.dart';
import 'package:kreso_frontend/features/pos/services/pos_outbox_service.dart';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<void> submitOrder(
    List<CartItem> items,
    String paymentMethod, {
    String? paymentAccount,
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
      if (paymentAccount != null && paymentAccount.isNotEmpty) 'payment_account': paymentAccount.toLowerCase(),
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


  /// Marks a table order as served in the hall
  Future<Map<String, dynamic>> markOrderServed(int orderId) async {
    try {
      final response = await _dio.post('/orders/$orderId/serve');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Ошибка обновления статуса: $e');
    }
  }

  /// Fetches active open dine-in tables
  Future<List<Map<String, dynamic>>> fetchActiveTables() async {
    try {
      final response = await _dio.get('/tables/active');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Не удалось загрузить столики: $e');
    }
  }

  /// Settles a table order (post-payment)
  Future<Map<String, dynamic>> settleTableOrder(
    int orderId,
    String paymentMethod, {
    String? paymentAccount,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/settle',
        data: {
          'payment_method': paymentMethod.toLowerCase(),
          if (paymentAccount != null && paymentAccount.isNotEmpty) 'payment_account': paymentAccount.toLowerCase(),
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Ошибка расчета столика: $e');
    }
  }

  /// Appends additional items (дозаказ) to an active table order
  Future<Map<String, dynamic>> appendItemsToTable(
    int orderId,
    List<CartItem> items,
  ) async {
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
        'quantity': item.quantity,
        'unit_price_override': item.menuItem.price + item.selectedOptionsPrice,
        if (item.selectedOptionsJson != null) 'options_json': item.selectedOptionsJson,
      };
    }).toList();

    try {
      final response = await _dio.post(
        '/orders/$orderId/append',
        data: {'items': orderItemsList},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Ошибка добавления к столику: $e');
    }
  }

  /// Splits selected items from an active table order and completes payment
  Future<Map<String, dynamic>> splitOrder(
    int orderId,
    List<Map<String, dynamic>> splitItems,
    String paymentMethod, {
    String? paymentAccount,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/split',
        data: {
          'items': splitItems,
          'payment_method': paymentMethod.toLowerCase(),
          if (paymentAccount != null && paymentAccount.isNotEmpty) 'payment_account': paymentAccount.toLowerCase(),
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Ошибка разделения чека: $e');
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

    await PosOutboxService.saveOrder(offlinePayload);
  }

  /// Cancels an order and releases table/stock
  Future<void> cancelOrder(int orderId) async {
    try {
      await _dio.patch(
        '/orders/$orderId/status',
        queryParameters: {'new_status': 'cancelled'},
      );
    } catch (e) {
      throw Exception('Не удалось отменить заказ: $e');
    }
  }
}
