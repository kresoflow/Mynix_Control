import 'package:flutter_bloc/flutter_bloc.dart';
import 'shift_event.dart';
import 'shift_state.dart';
import '../repository/shift_repository.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository repository;

  ShiftBloc(this.repository) : super(ShiftInitial()) {
    on<CheckCurrentShift>(_onCheckCurrentShift);
    on<OpenShiftRequested>(_onOpenShiftRequested);
    on<CloseShiftRequested>(_onCloseShiftRequested);
  }

  Future<void> _onCheckCurrentShift(CheckCurrentShift event, Emitter<ShiftState> emit) async {
    emit(ShiftLoading());
    try {
      final shift = await repository.getCurrentShift();
      if (shift != null) {
        emit(ShiftOpen(shift));
      } else {
        emit(ShiftClosed());
      }
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onOpenShiftRequested(OpenShiftRequested event, Emitter<ShiftState> emit) async {
    emit(ShiftLoading());
    try {
      await repository.openShift(event.openingCash);
      add(CheckCurrentShift());
    } catch (e) {
      emit(ShiftError(e.toString()));
      // Re-check to restore correct UI state
      add(CheckCurrentShift());
    }
  }

  Future<void> _onCloseShiftRequested(CloseShiftRequested event, Emitter<ShiftState> emit) async {
    emit(ShiftLoading());
    try {
      final result = await repository.closeShift(event.closingCashActual);
      emit(ShiftClosedSuccessfully(result));
      emit(ShiftClosed());
    } catch (e) {
      emit(ShiftError(e.toString()));
      // Re-check to restore correct UI state
      add(CheckCurrentShift());
    }
  }
}
