import 'package:equatable/equatable.dart';

abstract class KitchenState extends Equatable {
  const KitchenState();

  @override
  List<Object?> get props => [];
}

class KitchenLoading extends KitchenState {}

class KitchenLoaded extends KitchenState {
  final List<Map<String, dynamic>> orders;
  final bool isConnected;

  const KitchenLoaded({
    required this.orders,
    this.isConnected = false,
  });

  KitchenLoaded copyWith({
    List<Map<String, dynamic>>? orders,
    bool? isConnected,
  }) {
    return KitchenLoaded(
      orders: orders ?? this.orders,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [orders, isConnected];
}

class KitchenError extends KitchenState {
  final String message;

  const KitchenError(this.message);

  @override
  List<Object?> get props => [message];
}
