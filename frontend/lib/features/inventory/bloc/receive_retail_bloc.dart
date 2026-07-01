import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'receive_retail_event.dart';
import 'receive_retail_state.dart';

class ReceiveRetailBloc extends Bloc<ReceiveRetailEvent, ReceiveRetailState> {
  final InventoryRepository repository;

  ReceiveRetailBloc(this.repository) : super(const ReceiveRetailState()) {
    on<LoadRetailProducts>(_onLoadRetailProducts);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<SubmitReceiveRetail>(_onSubmitReceiveRetail);
  }

  Future<void> _onLoadRetailProducts(
    LoadRetailProducts event,
    Emitter<ReceiveRetailState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearSuccess: true));
    try {
      final products = await repository.getRetailProducts();
      emit(
        state.copyWith(
          isLoading: false,
          products: products,
          quantities: {}, // Reset quantities on load
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onUpdateQuantity(
    UpdateQuantity event,
    Emitter<ReceiveRetailState> emit,
  ) {
    final newQuantities = Map<int, double>.from(state.quantities);
    if (event.quantity <= 0) {
      newQuantities.remove(event.productId);
    } else {
      newQuantities[event.productId] = event.quantity;
    }
    emit(state.copyWith(quantities: newQuantities));
  }

  Future<void> _onSubmitReceiveRetail(
    SubmitReceiveRetail event,
    Emitter<ReceiveRetailState> emit,
  ) async {
    if (state.quantities.isEmpty) {
      emit(
        state.copyWith(
          error: 'Нет товаров для приемки',
          clearError: false,
          clearSuccess: true,
        ),
      );
      emit(
        state.copyWith(clearError: true),
      ); // Reset error state immediately so it can be shown again
      return;
    }

    emit(
      state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true),
    );

    try {
      // Send sequential requests for each product with quantity > 0
      for (final entry in state.quantities.entries) {
        if (entry.value > 0) {
          await repository.receiveStock(
            entry.key,
            entry.value,
            'Массовая приемка с витрины',
            isRetail: true,
          );
        }
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'Товары успешно оприходованы',
          quantities: {},
        ),
      );

      // Reload products to reflect updated stock
      add(LoadRetailProducts());
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
