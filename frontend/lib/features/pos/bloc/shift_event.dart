import 'package:equatable/equatable.dart';

abstract class ShiftEvent extends Equatable {
  const ShiftEvent();

  @override
  List<Object?> get props => [];
}

class CheckCurrentShift extends ShiftEvent {
  final bool? blindPosEnabled;

  const CheckCurrentShift({this.blindPosEnabled});

  @override
  List<Object?> get props => [blindPosEnabled];
}

class SetBlindPosMode extends ShiftEvent {
  final bool enabled;

  const SetBlindPosMode(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

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

class ToggleFinancialsVisibility extends ShiftEvent {
  final bool? unlock;

  const ToggleFinancialsVisibility({this.unlock});

  @override
  List<Object?> get props => [unlock];
}
