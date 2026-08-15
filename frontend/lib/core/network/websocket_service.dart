import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String _baseWsUrl = String.fromEnvironment(
    'WS_URL', 
    defaultValue: 'ws://127.0.0.1:8000/ws'
  );

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _currentTenantId;
  
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void connect(String tenantId) {
    if (_currentTenantId == tenantId && _channel != null) return;
    
    disconnect();
    _currentTenantId = tenantId;
    _connectInternal();
  }

  void _connectInternal() {
    if (_currentTenantId == null) return;

    final uri = Uri.parse('$_baseWsUrl/kitchen/$_currentTenantId');
    if (kDebugMode) {
      print('--> [WebSocket] Connecting to $uri');
    }

    try {
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          if (message == 'pong') return; // Ignore ping/pong
          
          if (kDebugMode) {
            print('<-- [WebSocket] Received: $message');
          }
          
          try {
            final data = jsonDecode(message);
            _messageController.add(data);
          } catch (e) {
            if (kDebugMode) print('<!> [WebSocket] JSON Decode error: $e');
          }
        },
        onDone: () {
          if (kDebugMode) print('<!> [WebSocket] Connection closed.');
          _scheduleReconnect();
        },
        onError: (error) {
          if (kDebugMode) print('<!> [WebSocket] Error: $error');
          _scheduleReconnect();
        },
      );

      // Setup Heartbeat (ping every 30 seconds)
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_channel != null) {
          _channel!.sink.add('ping');
        }
      });
      
      // Cancel any pending reconnects since we succeeded (or at least attempted)
      _reconnectTimer?.cancel();
      
    } catch (e) {
      if (kDebugMode) print('<!> [WebSocket] Connection exception: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _cleanUp();
    if (_currentTenantId == null) return; // User logged out

    if (kDebugMode) print('--> [WebSocket] Reconnecting in 5 seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _connectInternal();
    });
  }

  void _cleanUp() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    if (kDebugMode) print('--> [WebSocket] Disconnecting manually.');
    _currentTenantId = null;
    _reconnectTimer?.cancel();
    _cleanUp();
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

// Singleton for DI
final webSocketService = WebSocketService();
