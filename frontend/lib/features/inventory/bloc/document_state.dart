import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/features/inventory/models/supplier_transaction.dart';

enum DocumentStatus { initial, loading, success, failure }

class DocumentState extends Equatable {
  final DocumentStatus status;
  final List<InventoryDocument> documents;
  final List<Supplier> suppliers;
  final List<SupplierTransaction> supplierTransactions;
  final DocumentStatus transactionsStatus;
  final String? errorMessage;
  final bool isSubmitting;

  const DocumentState({
    this.status = DocumentStatus.initial,
    this.documents = const [],
    this.suppliers = const [],
    this.supplierTransactions = const [],
    this.transactionsStatus = DocumentStatus.initial,
    this.errorMessage,
    this.isSubmitting = false,
  });

  DocumentState copyWith({
    DocumentStatus? status,
    List<InventoryDocument>? documents,
    List<Supplier>? suppliers,
    List<SupplierTransaction>? supplierTransactions,
    DocumentStatus? transactionsStatus,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return DocumentState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      suppliers: suppliers ?? this.suppliers,
      supplierTransactions: supplierTransactions ?? this.supplierTransactions,
      transactionsStatus: transactionsStatus ?? this.transactionsStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        status,
        documents,
        suppliers,
        supplierTransactions,
        transactionsStatus,
        errorMessage,
        isSubmitting,
      ];
}
