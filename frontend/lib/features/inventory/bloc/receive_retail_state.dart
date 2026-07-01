import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class ReceiveRetailState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final List<Ingredient> products;
  final Map<int, double> quantities;
  final String? error;
  final String? successMessage;

  const ReceiveRetailState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.products = const [],
    this.quantities = const {},
    this.error,
    this.successMessage,
  });

  ReceiveRetailState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<Ingredient>? products,
    Map<int, double>? quantities,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ReceiveRetailState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      products: products ?? this.products,
      quantities: quantities ?? this.quantities,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSubmitting,
    products,
    quantities,
    error,
    successMessage,
  ];
}
