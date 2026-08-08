
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/pos_order.dart';
import '../repository/orders_repository.dart';

// --- Events ---
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {}

class CancelOrder extends OrdersEvent {
  final int orderId;
  const CancelOrder(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

// --- States ---
abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<PosOrder> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository repository;

  OrdersBloc({required this.repository}) : super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<CancelOrder>(_onCancelOrder);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    try {
      final orders = await repository.fetchOrders();
      // Sort orders descending by created_at
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError(e.toString()));
    }
  }

  Future<void> _onCancelOrder(CancelOrder event, Emitter<OrdersState> emit) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      try {
        await repository.cancelOrder(event.orderId);
        // Refresh the list after cancellation
        add(LoadOrders());
      } catch (e) {
        emit(OrdersError(e.toString()));
        // Attempt to load original list
        emit(OrdersLoaded(currentState.orders)); 
      }
    }
  }
}
