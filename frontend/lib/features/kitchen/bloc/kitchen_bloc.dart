import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'kitchen_event.dart';
import 'kitchen_state.dart';
import '../repository/kitchen_repository.dart';
import 'package:mynix_frontend/core/network/websocket_service.dart';
import 'package:mynix_frontend/core/utils/audio_helper.dart';

class KitchenBloc extends Bloc<KitchenEvent, KitchenState> {
  final KitchenRepository repository;
  StreamSubscription? _wsSubscription;

  KitchenBloc(this.repository) : super(KitchenLoading()) {
    on<ConnectKitchen>(_onConnectKitchen);
    on<DisconnectKitchen>(_onDisconnectKitchen);
    on<FetchActiveOrders>(_onFetchActiveOrders);
    on<KitchenOrderReceived>(_onOrderReceived);
    on<KitchenOrderStatusUpdated>(_onOrderStatusUpdated);
    on<MarkOrderReady>(_onMarkOrderReady);
  }

  Future<void> _onFetchActiveOrders(FetchActiveOrders event, Emitter<KitchenState> emit) async {
    emit(KitchenLoading());
    try {
      final orders = await repository.getActiveOrders();
      emit(KitchenLoaded(orders: orders, isConnected: false));
    } catch (e) {
      emit(KitchenError(e.toString()));
    }
  }

  Future<void> _onConnectKitchen(ConnectKitchen event, Emitter<KitchenState> emit) async {
    // We assume FetchActiveOrders was already called, or we call it first
    if (state is! KitchenLoaded) {
      try {
        final orders = await repository.getActiveOrders();
        emit(KitchenLoaded(orders: orders, isConnected: false));
      } catch (e) {
        emit(KitchenError(e.toString()));
        return;
      }
    }
    
    final currentState = state as KitchenLoaded;
    
    // Connect to WS messages
    try {
      _wsSubscription?.cancel();
      _wsSubscription = webSocketService.messages.listen(
        (data) {
          final eventType = data['event'];
          if (eventType == 'new_order') {
            add(KitchenOrderReceived(data['order']));
          } else if (eventType == 'status_update') {
            add(KitchenOrderStatusUpdated(data['order_id'], data['new_status']));
          }
        },
        onError: (error) {
          add(DisconnectKitchen()); // Disconnect on error
        },
        onDone: () {
          add(DisconnectKitchen());
        },
      );
      
      emit(currentState.copyWith(isConnected: true));
    } catch (e) {
      emit(KitchenError('Failed to connect to Kitchen WS: $e'));
    }
  }

  void _onDisconnectKitchen(DisconnectKitchen event, Emitter<KitchenState> emit) {
    _wsSubscription?.cancel();
    repository.disconnect();
    if (state is KitchenLoaded) {
      emit((state as KitchenLoaded).copyWith(isConnected: false));
    }
  }

  void _onOrderReceived(KitchenOrderReceived event, Emitter<KitchenState> emit) {
    if (state is KitchenLoaded) {
      final currentState = state as KitchenLoaded;
      
      // Check if order already exists to prevent duplicates
      final exists = currentState.orders.any((o) => o['id'] == event.order['id']);
      if (exists) return;

      // Play bell chime notification
      AudioHelper.playNewOrderSound();

      final updatedOrders = List<Map<String, dynamic>>.from(currentState.orders)..add(event.order);
      // Sort so oldest is first
      updatedOrders.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      
      emit(currentState.copyWith(orders: updatedOrders));
    }
  }

  void _onOrderStatusUpdated(KitchenOrderStatusUpdated event, Emitter<KitchenState> emit) {
    if (state is KitchenLoaded) {
      final currentState = state as KitchenLoaded;
      
      final updatedOrders = List<Map<String, dynamic>>.from(currentState.orders);
      
      if (event.newStatus == 'completed' || event.newStatus == 'cancelled') {
        // Remove from KDS if completed or cancelled
        updatedOrders.removeWhere((o) => o['id'] == event.orderId);
      } else {
        // Update status in place
        final index = updatedOrders.indexWhere((o) => o['id'] == event.orderId);
        if (index != -1) {
          updatedOrders[index] = Map<String, dynamic>.from(updatedOrders[index])..['status'] = event.newStatus;
        }
      }
      
      emit(currentState.copyWith(orders: updatedOrders));
    }
  }

  Future<void> _onMarkOrderReady(MarkOrderReady event, Emitter<KitchenState> emit) async {
    try {
      await repository.markOrderAsReady(event.orderId);
      
      if (state is KitchenLoaded) {
        final currentState = state as KitchenLoaded;
        final updatedOrders = currentState.orders.where((o) => o['id'] != event.orderId).toList();
        emit(currentState.copyWith(orders: updatedOrders));
      }
    } catch (e) {
      // Could show error notification
      print('Error marking order ready: $e');
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    repository.disconnect();
    return super.close();
  }
}
