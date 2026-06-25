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

class HoldCurrentCart extends CartEvent {
  final String holdName;
  const HoldCurrentCart(this.holdName);
  @override
  List<Object?> get props => [holdName];
}

class ResumeHeldCart extends CartEvent {
  final String cartId;
  const ResumeHeldCart(this.cartId);
  @override
  List<Object?> get props => [cartId];
}

// --- States ---
class CartState extends Equatable {
  final List<CartItem> items;
  final Map<String, List<CartItem>> heldCarts;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;
  
  const CartState({
    this.items = const [],
    this.heldCarts = const {},
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });
  
  double get total => items.fold(0.0, (sum, item) => sum + item.total);
  
  CartState copyWith({
    List<CartItem>? items,
    Map<String, List<CartItem>>? heldCarts,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return CartState(
      items: items ?? this.items,
      heldCarts: heldCarts ?? this.heldCarts,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError, // Let null clear it
      submitSuccess: submitSuccess ?? false, // Reset success unless explicitly true
    );
  }
  
  @override
  List<Object?> get props => [items, heldCarts, isSubmitting, submitError, submitSuccess];
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
    on<HoldCurrentCart>(_onHoldCurrentCart);
    on<ResumeHeldCart>(_onResumeHeldCart);
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
    emit(state.copyWith(items: const []));
  }

  Future<void> _onCheckoutCart(CheckoutCart event, Emitter<CartState> emit) async {
    if (state.items.isEmpty) return;
    
    emit(state.copyWith(isSubmitting: true));
    try {
      await orderRepository.submitOrder(state.items, event.paymentMethod);
      // On success, clear the cart and signal success
      emit(state.copyWith(items: const [], isSubmitting: false, submitSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }

  void _onHoldCurrentCart(HoldCurrentCart event, Emitter<CartState> emit) {
    if (state.items.isEmpty) return;
    
    final updatedHeld = Map<String, List<CartItem>>.from(state.heldCarts);
    updatedHeld[event.holdName] = List.from(state.items);
    
    emit(state.copyWith(
      items: const [],
      heldCarts: updatedHeld,
    ));
  }

  void _onResumeHeldCart(ResumeHeldCart event, Emitter<CartState> emit) {
    if (!state.heldCarts.containsKey(event.cartId)) return;

    final updatedHeld = Map<String, List<CartItem>>.from(state.heldCarts);
    final itemsToResume = updatedHeld.remove(event.cartId)!;

    // If current cart is NOT empty, we hold it automatically
    if (state.items.isNotEmpty) {
      final now = DateTime.now();
      final autoHoldName = 'Чек ${now.hour}:${now.minute.toString().padLeft(2, '0')} (Авто)';
      updatedHeld[autoHoldName] = List.from(state.items);
    }

    emit(state.copyWith(
      items: itemsToResume,
      heldCarts: updatedHeld,
    ));
  }
}
