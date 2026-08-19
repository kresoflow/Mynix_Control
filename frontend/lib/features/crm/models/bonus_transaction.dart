import 'package:equatable/equatable.dart';

class BonusTransaction extends Equatable {
  final int id;
  final int customerId;
  final int? orderId;
  final String type; // 'cashback', 'redeem', 'manual_add', 'manual_sub', 'welcome', 'birthday', 'expired'
  final double amount;
  final String? comment;
  final DateTime date;
  final int? createdBy;

  const BonusTransaction({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.type,
    required this.amount,
    this.comment,
    required this.date,
    this.createdBy,
  });

  bool get isCredit => type == 'cashback' || type == 'manual_add' || type == 'welcome' || type == 'birthday';

  String get typeLabel {
    switch (type) {
      case 'cashback':
        return 'Кешбэк за заказ';
      case 'redeem':
        return 'Оплата бонусами';
      case 'manual_add':
        return 'Бонус от заведения';
      case 'manual_sub':
        return 'Списание администратором';
      case 'welcome':
        return 'Приветственный бонус';
      case 'birthday':
        return 'Подарок на День Рождения';
      case 'expired':
        return 'Сгорание бонусов';
      default:
        return 'Бонусная операция';
    }
  }

  factory BonusTransaction.fromJson(Map<String, dynamic> json) {
    return BonusTransaction(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      orderId: json['order_id'],
      type: json['type']?.toString() ?? 'cashback',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment']?.toString(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      createdBy: json['created_by'],
    );
  }

  @override
  List<Object?> get props => [id, customerId, orderId, type, amount, comment, date, createdBy];
}
