import 'package:equatable/equatable.dart';

abstract class ShiftEvent extends Equatable {
  const ShiftEvent();

  @override
  List<Object?> get props => [];
}

class CheckCurrentShift extends ShiftEvent {}

class OpenShiftRequested extends ShiftEvent {
  final double openingCash;

  const OpenShiftRequested(this.openingCash);

  @override
  List<Object?> get props => [openingCash];
}

class CloseShiftRequested extends ShiftEvent {
  final double closingCashActual;

  const CloseShiftRequested(this.closingCashActual);

  @override
  List<Object?> get props => [closingCashActual];
}
