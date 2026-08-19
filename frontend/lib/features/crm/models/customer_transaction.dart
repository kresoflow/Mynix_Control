import 'package:equatable/equatable.dart';

enum CustomerTransactionType {
  orderDebt,
  orderDeposit,
  payment,
  deposit,
  adjustment;

  static CustomerTransactionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'order_debt':
        return CustomerTransactionType.orderDebt;
      case 'order_deposit':
        return CustomerTransactionType.orderDeposit;
      case 'payment':
        return CustomerTransactionType.payment;
      case 'deposit':
        return CustomerTransactionType.deposit;
      case 'adjustment':
        return CustomerTransactionType.adjustment;
      default:
        return CustomerTransactionType.payment;
    }
  }

  String toApiString() {
    switch (this) {
      case CustomerTransactionType.orderDebt:
        return 'order_debt';
      case CustomerTransactionType.orderDeposit:
        return 'order_deposit';
      case CustomerTransactionType.payment:
        return 'payment';
      case CustomerTransactionType.deposit:
        return 'deposit';
      case CustomerTransactionType.adjustment:
        return 'adjustment';
    }
  }

  String get label {
    switch (this) {
      case CustomerTransactionType.orderDebt:
        return 'Заказ (В долг)';
      case CustomerTransactionType.orderDeposit:
        return 'Заказ (С депозита)';
      case CustomerTransactionType.payment:
        return 'Погашение долга';
      case CustomerTransactionType.deposit:
        return 'Пополнение депозита';
      case CustomerTransactionType.adjustment:
        return 'Корректировка сальдо';
    }
  }
}

class CustomerTransaction extends Equatable {
  final int id;
  final int customerId;
  final int? orderId;
  final CustomerTransactionType type;
  final double amount;
  final String paymentMethod;
  final String? comment;
  final DateTime date;
  final int? createdBy;

  const CustomerTransaction({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.type,
    required this.amount,
    this.paymentMethod = 'cash',
    this.comment,
    required this.date,
    this.createdBy,
  });

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    return CustomerTransaction(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      orderId: json['order_id'],
      type: CustomerTransactionType.fromString(json['type']?.toString() ?? 'payment'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      comment: json['comment']?.toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toApiString(),
      'amount': amount,
      'payment_method': paymentMethod,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        orderId,
        type,
        amount,
        paymentMethod,
        comment,
        date,
        createdBy,
      ];
}
