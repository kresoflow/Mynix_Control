import 'package:equatable/equatable.dart';

abstract class ReceiveRetailEvent extends Equatable {
  const ReceiveRetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadRetailProducts extends ReceiveRetailEvent {}

class UpdateQuantity extends ReceiveRetailEvent {
  final int productId;
  final double quantity;

  const UpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class SubmitReceiveRetail extends ReceiveRetailEvent {}
