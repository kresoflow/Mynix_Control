// ==============================================================================
// МОДУЛЬ: Склад / Обработчики поставщиков и транзакций в DocumentBloc
// ДОМЕН: lib/features/inventory/bloc/document_bloc_supplier_handlers.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [ДЕКОМПОЗИЦИЯ] Вынос логики управления контрагентами из DocumentBloc:
// 1. Создание, обновление и удаление поставщиков (Suppliers).
// 2. Учет выплат, транзакций и сверки взаиморасчетов.
//
// ==============================================================================

part of 'document_bloc.dart';

extension DocumentBlocSupplierHandlers on DocumentBloc {
  Future<void> _onCreateSupplier(
    CreateSupplier event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.createSupplier(
        event.name,
        contactInfo: event.contactInfo,
        initialBalance: event.initialBalance,
      );
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(suppliers: suppliers, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: DocumentBloc._formatError(e)));
    }
  }

  Future<void> _onUpdateSupplier(
    UpdateSupplier event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.updateSupplier(
        event.id,
        name: event.name,
        contactInfo: event.contactInfo,
        isActive: event.isActive,
      );
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(suppliers: suppliers, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: DocumentBloc._formatError(e)));
    }
  }

  Future<void> _onDeleteSupplier(
    DeleteSupplier event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.deleteSupplier(event.id);
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(suppliers: suppliers, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: DocumentBloc._formatError(e)));
    }
  }

  Future<void> _onRecordSupplierPayment(
    RecordSupplierPayment event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.recordSupplierPayment(
        event.supplierId,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        comment: event.comment,
      );
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(suppliers: suppliers, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: DocumentBloc._formatError(e)));
    }
  }

  Future<void> _onLoadSupplierTransactions(
    LoadSupplierTransactions event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(transactionsStatus: DocumentStatus.loading));
    try {
      final txns = await _repository.getSupplierTransactions(event.supplierId);
      emit(
        state.copyWith(
          transactionsStatus: DocumentStatus.success,
          supplierTransactions: txns,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(transactionsStatus: DocumentStatus.failure, errorMessage: DocumentBloc._formatError(e)));
    }
  }

  Future<void> _refreshSupplierTxns(
    int supplierId,
    Emitter<DocumentState> emit,
  ) async {
    final txns = await _repository.getSupplierTransactions(supplierId);
    final suppliers = await _repository.getSuppliers();
    emit(
      state.copyWith(
        supplierTransactions: txns,
        suppliers: suppliers,
        clearError: true,
      ),
    );
  }

  Future<void> _onAddSupplierTransaction(
    AddSupplierTransaction event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.createSupplierTransaction(
        event.supplierId,
        type: event.type,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        comment: event.comment,
        date: event.date,
      );
      await _refreshSupplierTxns(event.supplierId, emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: DocumentBloc._formatError(e)));
    }
  }

  Future<void> _onUpdateSupplierTransaction(
    UpdateSupplierTransaction event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.updateSupplierTransaction(
        event.supplierId,
        event.transactionId,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        comment: event.comment,
        date: event.date,
      );
      await _refreshSupplierTxns(event.supplierId, emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: DocumentBloc._formatError(e)));
    }
  }

  Future<void> _onDeleteSupplierTransaction(
    DeleteSupplierTransaction event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.deleteSupplierTransaction(event.supplierId, event.transactionId);
      await _refreshSupplierTxns(event.supplierId, emit);
    } catch (e) {
      emit(state.copyWith(errorMessage: DocumentBloc._formatError(e)));
    }
  }
}
