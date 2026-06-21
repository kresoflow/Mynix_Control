import 'package:equatable/equatable.dart';

abstract class KitchenEvent extends Equatable {
  const KitchenEvent();

  @override
  List<Object?> get props => [];
}

class ConnectKitchen extends KitchenEvent {
  final String tenantId;
  const ConnectKitchen(this.tenantId);

  @override
  List<Object?> get props => [tenantId];
}

class DisconnectKitchen extends KitchenEvent {}

class FetchActiveOrders extends KitchenEvent {}

class KitchenOrderReceived extends KitchenEvent {
  final Map<String, dynamic> order;
  const KitchenOrderReceived(this.order);

  @override
  List<Object?> get props => [order];
}

class KitchenOrderStatusUpdated extends KitchenEvent {
  final int orderId;
  final String newStatus;
  const KitchenOrderStatusUpdated(this.orderId, this.newStatus);

  @override
  List<Object?> get props => [orderId, newStatus];
}

class MarkOrderReady extends KitchenEvent {
  final int orderId;
  const MarkOrderReady(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
