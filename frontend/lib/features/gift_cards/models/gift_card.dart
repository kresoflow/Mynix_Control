// ==============================================================================
// МОДУЛЬ: Подарочные карты (Gift Cards)
// ДОМЕН: lib/features/gift_cards/models/gift_card.dart
// ==============================================================================
import 'package:equatable/equatable.dart';

// ─── 1. Статусы и типы транзакций ─────────────────────────────────────────────

enum GiftCardStatus {
  active('active', 'Активна'),
  exhausted('exhausted', 'Исчерпана'),
  expired('expired', 'Истекла'),
  blocked('blocked', 'Заблокирована');

  final String value;
  final String label;
  const GiftCardStatus(this.value, this.label);

  static GiftCardStatus fromString(String? val) {
    if (val == null) return GiftCardStatus.active;
    final lower = val.toLowerCase();
    for (final s in GiftCardStatus.values) {
      if (s.value == lower || s.name.toLowerCase() == lower) return s;
    }
    return GiftCardStatus.active;
  }
}

enum GiftCardTransactionType {
  issue('issue', 'Эмиссия'),
  redeem('redeem', 'Списание'),
  topup('topup', 'Пополнение'),
  adjustment('adjustment', 'Корректировка');

  final String value;
  final String label;
  const GiftCardTransactionType(this.value, this.label);

  static GiftCardTransactionType fromString(String? val) {
    if (val == null) return GiftCardTransactionType.issue;
    final lower = val.toLowerCase();
    for (final t in GiftCardTransactionType.values) {
      if (t.value == lower || t.name.toLowerCase() == lower) return t;
    }
    return GiftCardTransactionType.issue;
  }
}

// ─── 2. Финансовая транзакция подарочной карты ────────────────────────────────

class GiftCardTransaction extends Equatable {
  final int id;
  final int giftCardId;
  final int? orderId;
  final GiftCardTransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? comment;
  final DateTime createdAt;
  final int? createdBy;

  const GiftCardTransaction({
    required this.id,
    required this.giftCardId,
    this.orderId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.comment,
    required this.createdAt,
    this.createdBy,
  });

  factory GiftCardTransaction.fromJson(Map<String, dynamic> json) {
    return GiftCardTransaction(
      id: json['id'] as int? ?? 0,
      giftCardId: json['gift_card_id'] as int? ?? 0,
      orderId: json['order_id'] as int?,
      type: GiftCardTransactionType.fromString(json['type']?.toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      createdBy: json['created_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'gift_card_id': giftCardId,
    'order_id': orderId,
    'type': type.value,
    'amount': amount,
    'balance_before': balanceBefore,
    'balance_after': balanceAfter,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
    'created_by': createdBy,
  };

  @override
  List<Object?> get props => [id, giftCardId, orderId, type, amount, balanceBefore, balanceAfter, comment, createdAt, createdBy];
}

// ─── 3. Доменная сущность Подарочной Карты ────────────────────────────────────

class GiftCard extends Equatable {
  final int id;
  final String code;
  final double initialBalance;
  final double currentBalance;
  final GiftCardStatus status;
  final bool isActive;
  final DateTime? expiryDate;
  final int? customerId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<GiftCardTransaction> transactions;

  const GiftCard({
    required this.id,
    required this.code,
    required this.initialBalance,
    required this.currentBalance,
    required this.status,
    this.isActive = true,
    this.expiryDate,
    this.customerId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.transactions = const [],
  });

  bool canRedeem(double amount) {
    if (!isActive || status != GiftCardStatus.active || isExpired) return false;
    return amount > 0 && currentBalance >= amount;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).isAfter(expiryDate!);
  }

  bool get hasBalance => currentBalance > 0.01;

  factory GiftCard.fromJson(Map<String, dynamic> json) {
    final rawTxs = json['transactions'] as List<dynamic>? ?? [];
    return GiftCard(
      id: json['id'] as int? ?? 0,
      code: json['code']?.toString() ?? '',
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      status: GiftCardStatus.fromString(json['status']?.toString()),
      isActive: json['is_active'] as bool? ?? true,
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'].toString()) : null,
      customerId: json['customer_id'] as int?,
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      transactions: rawTxs.map((t) => GiftCardTransaction.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'initial_balance': initialBalance,
    'current_balance': currentBalance,
    'status': status.value,
    'is_active': isActive,
    'expiry_date': expiryDate?.toIso8601String().split('T')[0],
    'customer_id': customerId,
    'notes': notes,
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  GiftCard copyWith({
    int? id,
    String? code,
    double? initialBalance,
    double? currentBalance,
    GiftCardStatus? status,
    bool? isActive,
    DateTime? expiryDate,
    int? customerId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GiftCardTransaction>? transactions,
  }) {
    return GiftCard(
      id: id ?? this.id,
      code: code ?? this.code,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      customerId: customerId ?? this.customerId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  List<Object?> get props => [id, code, initialBalance, currentBalance, status, isActive, expiryDate, customerId, notes, createdAt, updatedAt, transactions];
}
