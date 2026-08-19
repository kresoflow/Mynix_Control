import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double balance; // Positive = Deposit, Negative = Debt
  final double creditLimit;
  final double discountPercent;
  final String? notes;
  final bool isActive;
  final double totalSpent;
  final int ordersCount;
  final double averageCheck;
  final DateTime? lastVisitAt;
  final double bonusBalance;
  final String tierLevel;
  final DateTime? birthDate;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.balance = 0.0,
    this.creditLimit = 0.0,
    this.discountPercent = 0.0,
    this.notes,
    this.isActive = true,
    this.totalSpent = 0.0,
    this.ordersCount = 0,
    this.averageCheck = 0.0,
    this.lastVisitAt,
    this.bonusBalance = 0.0,
    this.tierLevel = 'standard',
    this.birthDate,
    this.createdAt,
  });

  bool get hasDebt => balance < -0.01;
  bool get hasDeposit => balance > 0.01;
  bool get isSettled => !hasDebt && !hasDeposit;

  String get tierName {
    switch (tierLevel.toLowerCase()) {
      case 'gold':
        return 'Gold (10%)';
      case 'silver':
        return 'Silver (5%)';
      case 'standard':
      default:
        return 'Standard (3%)';
    }
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Без имени',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      isActive: json['is_active'] ?? true,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      averageCheck: (json['average_check'] as num?)?.toDouble() ?? 0.0,
      lastVisitAt: json['last_visit_at'] != null ? DateTime.tryParse(json['last_visit_at']) : null,
      bonusBalance: (json['bonus_balance'] as num?)?.toDouble() ?? 0.0,
      tierLevel: json['tier_level']?.toString() ?? 'standard',
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'credit_limit': creditLimit,
      'discount_percent': discountPercent,
      'notes': notes,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String().split('T')[0],
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        address,
        balance,
        creditLimit,
        discountPercent,
        notes,
        isActive,
        totalSpent,
        ordersCount,
        averageCheck,
        lastVisitAt,
        bonusBalance,
        tierLevel,
        birthDate,
        createdAt,
      ];
}
