import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/network/websocket_service.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'document_event.dart';
import 'document_state.dart';

part 'document_bloc_supplier_handlers.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final InventoryRepository _repository;
  final IngredientBloc? _ingredientBloc;
  static IngredientBloc? globalIngredientBloc;
  static void Function()? onDocumentCompletedCallback;
  StreamSubscription? _wsSubscription;
  Timer? _wsDebounceTimer;

  DocumentBloc(this._repository, [this._ingredientBloc]) : super(const DocumentState()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<LoadSuppliers>(_onLoadSuppliers);
    on<CreateDocument>(_onCreateDocument);
    on<UpdateDocument>(_onUpdateDocument);
    on<DeleteDocument>(_onDeleteDocument);
    on<CompleteDocument>(_onCompleteDocument);
    on<CreateSupplier>(_onCreateSupplier);
    on<UpdateSupplier>(_onUpdateSupplier);
    on<DeleteSupplier>(_onDeleteSupplier);
    on<RecordSupplierPayment>(_onRecordSupplierPayment);
    on<LoadSupplierTransactions>(_onLoadSupplierTransactions);
    on<AddSupplierTransaction>(_onAddSupplierTransaction);
    on<UpdateSupplierTransaction>(_onUpdateSupplierTransaction);
    on<DeleteSupplierTransaction>(_onDeleteSupplierTransaction);

    _wsSubscription = webSocketService.messages.listen((data) {
      final event = data['event'];
      if (event == 'inventory_updated' ||
          event == 'document_created' ||
          event == 'document_completed') {
        _wsDebounceTimer?.cancel();
        _wsDebounceTimer = Timer(const Duration(milliseconds: 350), () {
          add(const LoadDocuments());
        });
      }
    });
  }

  @override
  Future<void> close() {
    _wsDebounceTimer?.cancel();
    _wsSubscription?.cancel();
    return super.close();
  }

  static String _formatError(Object e) {
    if (e is DioException) return e.message ?? e.toString();
    final str = e.toString();
    if (str.contains(': ')) {
      final lastPart = str.split(': ').last.trim();
      if (lastPart.isNotEmpty && !lastPart.startsWith('Exception')) return lastPart;
    }
    if (str.startsWith('Exception: ')) return str.substring(11).trim();
    return str;
  }

  void _notifyDocumentCompleted() {
    _ingredientBloc?.add(const LoadIngredients());
    globalIngredientBloc?.add(const LoadIngredients());
    onDocumentCompletedCallback?.call();
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    if (state.documents.isEmpty) {
      emit(state.copyWith(status: DocumentStatus.loading));
    }
    try {
      final documents = await _repository.getDocuments(type: event.type);
      emit(
        state.copyWith(
          status: DocumentStatus.success, 
          documents: documents,
          clearError: true,
        ),
      );
    } catch (e) {
      if (state.documents.isEmpty) {
        emit(state.copyWith(status: DocumentStatus.failure, errorMessage: _formatError(e)));
      } else {
        emit(state.copyWith(errorMessage: _formatError(e)));
      }
    }
  }

  Future<void> _onLoadSuppliers(
    LoadSuppliers event,
    Emitter<DocumentState> emit,
  ) async {
    if (state.suppliers.isEmpty) {
      emit(state.copyWith(status: DocumentStatus.loading));
    }
    try {
      final suppliers = await _repository.getSuppliers();
      emit(state.copyWith(suppliers: suppliers, clearError: true));
    } catch (e) {
      if (state.suppliers.isEmpty) {
        emit(
          state.copyWith(
            status: DocumentStatus.failure,
            errorMessage: _formatError(e),
          ),
        );
      } else {
        emit(state.copyWith(errorMessage: _formatError(e)));
      }
    }
  }

  Future<void> _refreshData(
    Emitter<DocumentState> emit,
  ) async {
    final documents = await _repository.getDocuments();
    final suppliers = await _repository.getSuppliers();
    emit(
      state.copyWith(
        isSubmitting: false, 
        documents: documents, 
        suppliers: suppliers,
        clearError: true,
      ),
    );
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
        _notifyDocumentCompleted();
      }
      await _refreshData(emit);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _formatError(e)));
    }
  }

  Future<void> _onUpdateDocument(
    UpdateDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      final updatedDoc = await _repository.updateDocument(event.id, event.data);
      if (event.data['status'] == 'completed') {
        await _repository.completeDocument(updatedDoc.id);
        _notifyDocumentCompleted();
      }
      await _refreshData(emit);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _formatError(e)));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _repository.deleteDocument(event.documentId);
      await _refreshData(emit);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _formatError(e)));
    }
  }

  Future<void> _onCompleteDocument(
    CompleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _repository.completeDocument(event.documentId);
      _notifyDocumentCompleted();
      await _refreshData(emit);
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: _formatError(e)));
    }
  }
}
