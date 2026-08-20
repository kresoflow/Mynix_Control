import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/offline_order_payload.dart';
import '../pos_outbox_service.dart';

class LocalPosServer {
  static HttpServer? _server;
  static int port = 8080;
  static String? localIpAddress;
  static ValueChanged<OfflineOrderPayload>? onOrderReceived;
  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);

  static bool get isRunning => _server != null;

  /// Starts the embedded Dart HTTP server on Cashier PC
  static Future<bool> start({int serverPort = 8080, ValueChanged<OfflineOrderPayload>? onOrder}) async {
    if (kIsWeb) return false; // Embedded HttpServer not applicable in browser

    try {
      port = serverPort;
      onOrderReceived = onOrder;

      // Discover local LAN IP (e.g. 192.168.1.xxx)
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.') || addr.address.startsWith('10.') || addr.address.startsWith('172.')) {
            localIpAddress = addr.address;
            break;
          }
        }
        if (localIpAddress != null) break;
      }

      localIpAddress ??= '127.0.0.1';

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server!.listen(_handleRequest);
      isRunningNotifier.value = true;
      return true;
    } catch (_) {
      isRunningNotifier.value = false;
      return false;
    }
  }

  /// Stops the local server
  static Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      isRunningNotifier.value = false;
    }
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    // CORS headers for local LAN clients
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      final path = request.uri.path;

      if (path == '/health' && request.method == 'GET') {
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({
            'status': 'ok',
            'app': 'Mynix Control Master POS',
            'ip': localIpAddress,
            'port': port,
            'pending_orders': PosOutboxService.pendingCount,
          }));
        await request.response.close();
        return;
      }

      if (path == '/api/local/order' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final Map<String, dynamic> body = jsonDecode(content);

        final order = OfflineOrderPayload.fromJson(body);
        await PosOutboxService.saveOrder(order);

        if (onOrderReceived != null) {
          onOrderReceived!(order);
        }

        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.created
          ..write(jsonEncode({
            'success': true,
            'client_uuid': order.clientUuid,
            'order_number': order.orderNumber,
            'message': 'Order accepted by Cashier Master POS',
          }));
        await request.response.close();
        return;
      }

      // Default 404
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      await request.response.close();
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }
}
