import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/inventory/models/supplier_transaction.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentEvent {
  final String? type;

  const LoadDocuments({this.type});

  @override
  List<Object?> get props => [type];
}

class LoadSuppliers extends DocumentEvent {}

class CreateDocument extends DocumentEvent {
  final Map<String, dynamic> data;

  const CreateDocument(this.data);

  @override
  List<Object?> get props => [data];
}

class CompleteDocument extends DocumentEvent {
  final int documentId;

  const CompleteDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class CreateSupplier extends DocumentEvent {
  final String name;
  final String? contactInfo;
  final double? initialBalance;

  const CreateSupplier(this.name, {this.contactInfo, this.initialBalance});

  @override
  List<Object?> get props => [name, contactInfo, initialBalance];
}

class UpdateSupplier extends DocumentEvent {
  final int id;
  final String name;
  final String? contactInfo;
  final bool? isActive;

  const UpdateSupplier(this.id, {required this.name, this.contactInfo, this.isActive});

  @override
  List<Object?> get props => [id, name, contactInfo, isActive];
}

class DeleteSupplier extends DocumentEvent {
  final int id;

  const DeleteSupplier(this.id);

  @override
  List<Object?> get props => [id];
}

class RecordSupplierPayment extends DocumentEvent {
  final int supplierId;
  final double amount;
  final String paymentMethod;
  final String? comment;

  const RecordSupplierPayment(
    this.supplierId, {
    required this.amount,
    this.paymentMethod = 'cash',
    this.comment,
  });

  @override
  List<Object?> get props => [supplierId, amount, paymentMethod, comment];
}

// --- Supplier Transactions ---

class LoadSupplierTransactions extends DocumentEvent {
  final int supplierId;

  const LoadSupplierTransactions(this.supplierId);

  @override
  List<Object?> get props => [supplierId];
}

class AddSupplierTransaction extends DocumentEvent {
  final int supplierId;
  final SupplierTransactionType type;
  final double amount;
  final String paymentMethod;
  final String? comment;
  final DateTime? date;

  const AddSupplierTransaction(
    this.supplierId, {
    required this.type,
    required this.amount,
    this.paymentMethod = 'cash',
    this.comment,
    this.date,
  });

  @override
  List<Object?> get props => [supplierId, type, amount, paymentMethod, comment, date];
}

class UpdateSupplierTransaction extends DocumentEvent {
  final int supplierId;
  final int transactionId;
  final double? amount;
  final String? paymentMethod;
  final String? comment;
  final DateTime? date;

  const UpdateSupplierTransaction(
    this.supplierId,
    this.transactionId, {
    this.amount,
    this.paymentMethod,
    this.comment,
    this.date,
  });

  @override
  List<Object?> get props => [supplierId, transactionId, amount, paymentMethod, comment, date];
}

class DeleteSupplierTransaction extends DocumentEvent {
  final int supplierId;
  final int transactionId;

  const DeleteSupplierTransaction(this.supplierId, this.transactionId);

  @override
  List<Object?> get props => [supplierId, transactionId];
}
