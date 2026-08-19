import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'document_event.dart';
import 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final InventoryRepository _repository;

  DocumentBloc(this._repository) : super(const DocumentState()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<LoadSuppliers>(_onLoadSuppliers);
    on<CreateDocument>(_onCreateDocument);
    on<CompleteDocument>(_onCompleteDocument);
    on<CreateSupplier>(_onCreateSupplier);
    on<UpdateSupplier>(_onUpdateSupplier);
    on<DeleteSupplier>(_onDeleteSupplier);
    on<RecordSupplierPayment>(_onRecordSupplierPayment);
    on<LoadSupplierTransactions>(_onLoadSupplierTransactions);
    on<AddSupplierTransaction>(_onAddSupplierTransaction);
    on<UpdateSupplierTransaction>(_onUpdateSupplierTransaction);
    on<DeleteSupplierTransaction>(_onDeleteSupplierTransaction);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(status: DocumentStatus.loading));
    try {
      final documents = await _repository.getDocuments(type: event.type);
      emit(state.copyWith(
        status: DocumentStatus.success,
        documents: documents,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocumentStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSuppliers(
    LoadSuppliers event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateDocument(
    CreateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      final createdDoc = await _repository.createDocument(event.data);
      if (event.data['status'] == 'completed') {
        await _repository.completeDocument(createdDoc.id);
      }
      final documents = await _repository.getDocuments();
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(
        isSubmitting: false,
        documents: documents,
        suppliers: suppliers,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCompleteDocument(
    CompleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _repository.completeDocument(event.documentId);
      final documents = await _repository.getDocuments();
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(isSubmitting: false, documents: documents, suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

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
      emit(state.copyWith(suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
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
      emit(state.copyWith(suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteSupplier(
    DeleteSupplier event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.deleteSupplier(event.id);
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
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
      emit(state.copyWith(suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  // --- Transactions & Ledger ---

  Future<void> _onLoadSupplierTransactions(
    LoadSupplierTransactions event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(transactionsStatus: DocumentStatus.loading));
    try {
      final txns = await _repository.getSupplierTransactions(event.supplierId);
      emit(state.copyWith(
        transactionsStatus: DocumentStatus.success,
        supplierTransactions: txns,
      ));
    } catch (e) {
      emit(state.copyWith(
        transactionsStatus: DocumentStatus.failure,
        errorMessage: e.toString(),
      ));
    }
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
      final txns = await _repository.getSupplierTransactions(event.supplierId);
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(supplierTransactions: txns, suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
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
      final txns = await _repository.getSupplierTransactions(event.supplierId);
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(supplierTransactions: txns, suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteSupplierTransaction(
    DeleteSupplierTransaction event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _repository.deleteSupplierTransaction(event.supplierId, event.transactionId);
      final txns = await _repository.getSupplierTransactions(event.supplierId);
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(supplierTransactions: txns, suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
