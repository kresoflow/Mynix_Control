import 'package:equatable/equatable.dart';
import 'package:retail_os_frontend/features/inventory/models/document.dart';
import 'package:retail_os_frontend/features/inventory/models/supplier.dart';

enum DocumentStatus { initial, loading, success, failure }

class DocumentState extends Equatable {
  final DocumentStatus status;
  final List<InventoryDocument> documents;
  final List<Supplier> suppliers;
  final String? errorMessage;
  final bool isSubmitting;

  const DocumentState({
    this.status = DocumentStatus.initial,
    this.documents = const [],
    this.suppliers = const [],
    this.errorMessage,
    this.isSubmitting = false,
  });

  DocumentState copyWith({
    DocumentStatus? status,
    List<InventoryDocument>? documents,
    List<Supplier>? suppliers,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return DocumentState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      suppliers: suppliers ?? this.suppliers,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [status, documents, suppliers, errorMessage, isSubmitting];
}
