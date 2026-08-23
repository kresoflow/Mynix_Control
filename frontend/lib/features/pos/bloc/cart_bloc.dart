import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/pos/models/cart_item.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/repository/order_repository.dart';

// --- Events ---
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddItemToCart extends CartEvent {
  final MenuItem item;
  final String? selectedOptionsJson;
  final double selectedOptionsPrice;
  const AddItemToCart(this.item, {this.selectedOptionsJson, this.selectedOptionsPrice = 0.0});
  
  @override
  List<Object?> get props => [item, selectedOptionsJson, selectedOptionsPrice];
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

class SelectCustomer extends CartEvent {
  final dynamic customer;
  const SelectCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class SetBonusToSpend extends CartEvent {
  final double amount;
  const SetBonusToSpend(this.amount);

  @override
  List<Object?> get props => [amount];
}

class SetTableNumber extends CartEvent {
  final String? tableNumber;
  const SetTableNumber(this.tableNumber);

  @override
  List<Object?> get props => [tableNumber];
}

class CheckoutCart extends CartEvent {
  final String paymentMethod;
  final String? note;
  final String? tableNumber;
  final String? orderSource;
  const CheckoutCart({
    this.paymentMethod = 'CASH',
    this.note,
    this.tableNumber,
    this.orderSource,
  });
  
  @override
  List<Object?> get props => [paymentMethod, note, tableNumber, orderSource];
}

class HoldCurrentCart extends CartEvent {
  const HoldCurrentCart();
  @override
  List<Object?> get props => [];
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
  final int holdCounter;
  final dynamic selectedCustomer;
  final double bonusToSpend;
  final String? tableNumber;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;
  
  const CartState({
    this.items = const [],
    this.heldCarts = const {},
    this.holdCounter = 1,
    this.selectedCustomer,
    this.bonusToSpend = 0.0,
    this.tableNumber,
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });
  
  double get total => items.fold(0.0, (sum, item) => sum + item.total);
  double get payableTotal => (total - bonusToSpend).clamp(0.0, double.infinity);
  
  CartState copyWith({
    List<CartItem>? items,
    Map<String, List<CartItem>>? heldCarts,
    int? holdCounter,
    dynamic selectedCustomer,
    bool clearCustomer = false,
    double? bonusToSpend,
    String? tableNumber,
    bool clearTableNumber = false,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
  }) {
    return CartState(
      items: items ?? this.items,
      heldCarts: heldCarts ?? this.heldCarts,
      holdCounter: holdCounter ?? this.holdCounter,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      bonusToSpend: clearCustomer ? 0.0 : (bonusToSpend ?? this.bonusToSpend),
      tableNumber: clearTableNumber ? null : (tableNumber ?? this.tableNumber),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      submitSuccess: submitSuccess ?? false,
    );
  }
  
  @override
  List<Object?> get props => [
        items,
        heldCarts,
        holdCounter,
        selectedCustomer,
        bonusToSpend,
        tableNumber,
        isSubmitting,
        submitError,
        submitSuccess,
      ];
}

// --- Bloc ---
class CartBloc extends Bloc<CartEvent, CartState> {
  final OrderRepository orderRepository;
  
  CartBloc(this.orderRepository) : super(const CartState()) {
    on<AddItemToCart>(_onAddItemToCart);
    on<RemoveItemFromCart>(_onRemoveItemFromCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<SelectCustomer>(_onSelectCustomer);
    on<SetBonusToSpend>(_onSetBonusToSpend);
    on<SetTableNumber>(_onSetTableNumber);
    on<CheckoutCart>(_onCheckoutCart);
    on<HoldCurrentCart>(_onHoldCurrentCart);
    on<ResumeHeldCart>(_onResumeHeldCart);
  }

  void _onSelectCustomer(SelectCustomer event, Emitter<CartState> emit) {
    emit(state.copyWith(
      selectedCustomer: event.customer,
      clearCustomer: event.customer == null,
      bonusToSpend: 0.0,
    ));
  }

  void _onSetBonusToSpend(SetBonusToSpend event, Emitter<CartState> emit) {
    emit(state.copyWith(bonusToSpend: event.amount.clamp(0.0, state.total)));
  }

  void _onSetTableNumber(SetTableNumber event, Emitter<CartState> emit) {
    emit(state.copyWith(
      tableNumber: event.tableNumber,
      clearTableNumber: event.tableNumber == null,
    ));
  }

  void _onAddItemToCart(AddItemToCart event, Emitter<CartState> emit) {
    final existingIndex = state.items.indexWhere(
      (item) => item.menuItem.id == event.item.id && 
                item.selectedOptionsJson == event.selectedOptionsJson
    );
    
    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List.from(state.items);
      final current = updatedItems[existingIndex];
      updatedItems[existingIndex] = current.copyWith(quantity: current.quantity + 1);
    } else {
      updatedItems = List.from(state.items)..add(
        CartItem(
          menuItem: event.item, 
          quantity: 1,
          selectedOptionsJson: event.selectedOptionsJson,
          selectedOptionsPrice: event.selectedOptionsPrice,
        )
      );
    }
    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveItemFromCart(RemoveItemFromCart event, Emitter<CartState> emit) {
    final updatedItems = state.items.where((item) => item.id != event.cartItemId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateCartItemQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(RemoveItemFromCart(event.cartItemId));
      return;
    }
    
    final updatedItems = state.items.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(state.copyWith(items: const [], clearCustomer: true, clearTableNumber: true));
  }

  Future<void> _onCheckoutCart(CheckoutCart event, Emitter<CartState> emit) async {
    if (state.items.isEmpty) return;
    
    emit(state.copyWith(isSubmitting: true));
    try {
      final customerId = state.selectedCustomer != null ? state.selectedCustomer.id as int : null;
      await orderRepository.submitOrder(
        state.items,
        event.paymentMethod,
        customerId: customerId,
        bonusSpent: state.bonusToSpend > 0 ? state.bonusToSpend : null,
        note: event.note,
        tableNumber: event.tableNumber ?? state.tableNumber,
        orderSource: event.orderSource,
      );
      emit(state.copyWith(items: const [], clearCustomer: true, clearTableNumber: true, isSubmitting: false, submitSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }

  void _onHoldCurrentCart(HoldCurrentCart event, Emitter<CartState> emit) {
    if (state.items.isEmpty) return;
    
    final updatedHeld = Map<String, List<CartItem>>.from(state.heldCarts);
    final now = DateTime.now();
    final name = 'Чек #${state.holdCounter} (${now.hour}:${now.minute.toString().padLeft(2, '0')})';
    
    updatedHeld[name] = List.from(state.items);
    
    emit(state.copyWith(
      items: const [],
      heldCarts: updatedHeld,
      holdCounter: state.holdCounter + 1,
    ));
  }

  void _onResumeHeldCart(ResumeHeldCart event, Emitter<CartState> emit) {
    if (!state.heldCarts.containsKey(event.cartId)) return;

    final updatedHeld = Map<String, List<CartItem>>.from(state.heldCarts);
    final itemsToResume = updatedHeld.remove(event.cartId)!;

    if (state.items.isNotEmpty) {
      final now = DateTime.now();
      final autoHoldName = 'Чек #${state.holdCounter} (Авто, ${now.hour}:${now.minute.toString().padLeft(2, '0')})';
      updatedHeld[autoHoldName] = List.from(state.items);
    }

    emit(state.copyWith(
      items: itemsToResume,
      heldCarts: updatedHeld,
      holdCounter: state.items.isNotEmpty ? state.holdCounter + 1 : state.holdCounter,
    ));
  }
}
