import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:retail_os_frontend/features/pos/models/cart_item.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';
import 'package:retail_os_frontend/features/pos/repository/order_repository.dart';

// --- Events ---
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddItemToCart extends CartEvent {
  final MenuItem item;
  const AddItemToCart(this.item);
  
  @override
  List<Object?> get props => [item];
}

class RemoveItemFromCart extends CartEvent {
  final String cartItemId;
  const RemoveItemFromCart(this.cartItemId);
  
  @override
  List<Object?> get props => [cartItemId];
}

class UpdateCartItemQuantity extends CartEvent {
  final String cartItemId;
  final int quantity;
  const UpdateCartItemQuantity(this.cartItemId, this.quantity);

  @override
  List<Object?> get props => [cartItemId, quantity];
}

class ClearCart extends CartEvent {}

class CheckoutCart extends CartEvent {
  final String paymentMethod;
  const CheckoutCart({this.paymentMethod = 'CASH'});
  
  @override
  List<Object?> get props => [paymentMethod];
}

// --- States ---
class CartState extends Equatable {
  final List<CartItem> items;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;
  
  const CartState({
    this.items = const [],
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });
  
  double get total => items.fold(0.0, (sum, item) => sum + item.total);
  
  CartState copyWith({
    List<CartItem>? items,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return CartState(
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError, // Let null clear it
      submitSuccess: submitSuccess ?? false, // Reset success unless explicitly true
    );
  }
  
  @override
  List<Object?> get props => [items, isSubmitting, submitError, submitSuccess];
}

// --- Bloc ---
class CartBloc extends Bloc<CartEvent, CartState> {
  final OrderRepository orderRepository;
  
  CartBloc(this.orderRepository) : super(const CartState()) {
    on<AddItemToCart>(_onAddItemToCart);
    on<RemoveItemFromCart>(_onRemoveItemFromCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<CheckoutCart>(_onCheckoutCart);
  }

  void _onAddItemToCart(AddItemToCart event, Emitter<CartState> emit) {
    // Check if item already exists in cart, then just increase quantity
    final existingIndex = state.items.indexWhere((i) => i.menuItem.id == event.item.id);
    
    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
      emit(state.copyWith(items: updatedItems));
    } else {
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Pseudo UUID
        menuItem: event.item,
        quantity: 1,
      );
      emit(state.copyWith(items: [...state.items, newItem]));
    }
  }

  void _onRemoveItemFromCart(RemoveItemFromCart event, Emitter<CartState> emit) {
    final updatedItems = state.items.where((item) => item.id != event.cartItemId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateCartItemQuantity event, Emitter<CartState> emit) {
    final updatedItems = state.items.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(quantity: event.quantity.clamp(1, 99));
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState(items: []));
  }

  Future<void> _onCheckoutCart(CheckoutCart event, Emitter<CartState> emit) async {
    if (state.items.isEmpty) return;
    
    emit(state.copyWith(isSubmitting: true));
    try {
      await orderRepository.submitOrder(state.items, event.paymentMethod);
      // On success, clear the cart and signal success
      emit(const CartState(items: [], submitSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }
}
