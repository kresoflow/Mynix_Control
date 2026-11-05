import 'package:equatable/equatable.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';
import 'package:kreso_frontend/features/inventory/models/supplier_transaction.dart';

enum DocumentStatus { initial, loading, success, failure }

class DocumentState extends Equatable {
  final DocumentStatus status;
  final List<InventoryDocument> documents;
  final List<Supplier> suppliers;
  final DocumentStatus suppliersStatus;
  final List<SupplierTransaction> supplierTransactions;
  final DocumentStatus transactionsStatus;
  final String? errorMessage;
  final bool isSubmitting;

  const DocumentState({
    this.status = DocumentStatus.initial,
    this.documents = const [],
    this.suppliers = const [],
    this.suppliersStatus = DocumentStatus.initial,
    this.supplierTransactions = const [],
    this.transactionsStatus = DocumentStatus.initial,
    this.errorMessage,
    this.isSubmitting = false,
  });

  DocumentState copyWith({
    DocumentStatus? status,
    List<InventoryDocument>? documents,
    List<Supplier>? suppliers,
    DocumentStatus? suppliersStatus,
    List<SupplierTransaction>? supplierTransactions,
    DocumentStatus? transactionsStatus,
    String? errorMessage,
    bool? isSubmitting,
    bool clearError = false,
  }) {
    return DocumentState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      suppliers: suppliers ?? this.suppliers,
      suppliersStatus: suppliersStatus ?? this.suppliersStatus,
      supplierTransactions: supplierTransactions ?? this.supplierTransactions,
      transactionsStatus: transactionsStatus ?? this.transactionsStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isLoading => status == DocumentStatus.loading;
  bool get isSuppliersLoading => suppliersStatus == DocumentStatus.loading;

  @override
  List<Object?> get props => [
        status,
        documents,
        suppliers,
        suppliersStatus,
        supplierTransactions,
        transactionsStatus,
        errorMessage,
        isSubmitting,
      ];
}
