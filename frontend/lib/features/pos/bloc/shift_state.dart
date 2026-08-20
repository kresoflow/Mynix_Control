import 'package:equatable/equatable.dart';

abstract class ShiftState extends Equatable {
  const ShiftState();

  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}

class ShiftLoading extends ShiftState {}

class ShiftOpen extends ShiftState {
  final Map<String, dynamic> shiftDetails;
  final bool isFinancialsUnlocked;

  const ShiftOpen(this.shiftDetails, {this.isFinancialsUnlocked = false});

  @override
  List<Object?> get props => [shiftDetails, isFinancialsUnlocked];
}

class ShiftClosed extends ShiftState {}

class ShiftClosedSuccessfully extends ShiftState {
  final Map<String, dynamic> report;

  const ShiftClosedSuccessfully(this.report);

  @override
  List<Object?> get props => [report];
}

class ShiftError extends ShiftState {
  final String message;

  const ShiftError(this.message);

  @override
  List<Object?> get props => [message];
}
