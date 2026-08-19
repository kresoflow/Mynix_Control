import 'package:equatable/equatable.dart';

enum SupplierTransactionType {
  invoice,
  payment,
  manualDebt,
  adjustment;

  static SupplierTransactionType fromString(String val) {
    switch (val) {
      case 'invoice':
        return SupplierTransactionType.invoice;
      case 'payment':
        return SupplierTransactionType.payment;
      case 'manual_debt':
        return SupplierTransactionType.manualDebt;
      case 'adjustment':
        return SupplierTransactionType.adjustment;
      default:
        return SupplierTransactionType.payment;
    }
  }

  String toApiString() {
    switch (this) {
      case SupplierTransactionType.invoice:
        return 'invoice';
      case SupplierTransactionType.payment:
        return 'payment';
      case SupplierTransactionType.manualDebt:
        return 'manual_debt';
      case SupplierTransactionType.adjustment:
        return 'adjustment';
    }
  }

  String get label {
    switch (this) {
      case SupplierTransactionType.invoice:
        return 'Накладная (Приход)';
      case SupplierTransactionType.payment:
        return 'Выплата (Гашение долга)';
      case SupplierTransactionType.manualDebt:
        return 'Начальный / Ручной долг';
      case SupplierTransactionType.adjustment:
        return 'Корректировка сальдо';
    }
  }
}

class SupplierTransaction extends Equatable {
  final int id;
  final int supplierId;
  final int? documentId;
  final SupplierTransactionType type;
  final double amount;
  final String paymentMethod;
  final String? comment;
  final DateTime date;
  final int? createdBy;
  final String? documentInvoiceNumber;

  const SupplierTransaction({
    required this.id,
    required this.supplierId,
    this.documentId,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    this.comment,
    required this.date,
    this.createdBy,
    this.documentInvoiceNumber,
  });

  factory SupplierTransaction.fromJson(Map<String, dynamic> json) {
    return SupplierTransaction(
      id: json['id'] as int,
      supplierId: json['supplier_id'] as int,
      documentId: json['document_id'] as int?,
      type: SupplierTransactionType.fromString(json['type'] as String? ?? 'payment'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      comment: json['comment'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      createdBy: json['created_by'] as int?,
      documentInvoiceNumber: json['document_invoice_number'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        supplierId,
        documentId,
        type,
        amount,
        paymentMethod,
        comment,
        date,
        createdBy,
        documentInvoiceNumber,
      ];
}
