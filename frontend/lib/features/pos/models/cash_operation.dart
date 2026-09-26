// ==============================================================================
//  Kreso Flow — POS: Cash Operation Models
//  [ФИНАНСЫ] Модели кассовых операций (внесение, инкассация, служебный расход)
// ==============================================================================

import 'package:equatable/equatable.dart';

/// Тип кассовой операции
enum CashOpType {
  deposit,
  withdrawal;

  static CashOpType fromString(String value) {
    if (value.toLowerCase() == 'deposit') {
      return CashOpType.deposit;
    }
    return CashOpType.withdrawal;
  }

  String get apiValue => this == CashOpType.deposit ? 'deposit' : 'withdrawal';

  String get label => this == CashOpType.deposit ? 'Внесение' : 'Расход / Инкассация';
}

/// Модель отдельной кассовой операции
class CashOperation extends Equatable {
  final int id;
  final int shiftId;
  final int userId;
  final String? userName;
  final CashOpType type;
  final double amount;
  final String category;
  final String? comment;
  final DateTime createdAt;
  final String? clientUuid;

  const CashOperation({
    required this.id,
    required this.shiftId,
    required this.userId,
    this.userName,
    required this.type,
    required this.amount,
    required this.category,
    this.comment,
    required this.createdAt,
    this.clientUuid,
  });

  factory CashOperation.fromJson(Map<String, dynamic> json) {
    return CashOperation(
      id: json['id'] as int? ?? 0,
      shiftId: json['shift_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      userName: json['user_name'] as String?,
      type: CashOpType.fromString(json['type']?.toString() ?? 'deposit'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Общее',
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      clientUuid: json['client_uuid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shift_id': shiftId,
      'user_id': userId,
      'user_name': userName,
      'type': type.apiValue,
      'amount': amount,
      'category': category,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'client_uuid': clientUuid,
    };
  }

  @override
  List<Object?> get props => [
        id,
        shiftId,
        userId,
        userName,
        type,
        amount,
        category,
        comment,
        createdAt,
        clientUuid,
      ];
}

/// Сводный отчет по кассовым операциям смены
class CashOperationsSummary extends Equatable {
  final int shiftId;
  final double openingCash;
  final double totalDeposits;
  final double totalWithdrawals;
  final double currentExpectedCash;
  final int operationsCount;
  final List<CashOperation> operations;

  const CashOperationsSummary({
    required this.shiftId,
    required this.openingCash,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.currentExpectedCash,
    required this.operationsCount,
    this.operations = const [],
  });

  factory CashOperationsSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['operations'] as List<dynamic>?) ?? [];
    return CashOperationsSummary(
      shiftId: json['shift_id'] as int? ?? 0,
      openingCash: (json['opening_cash'] as num?)?.toDouble() ?? 0.0,
      totalDeposits: (json['total_deposits'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals: (json['total_withdrawals'] as num?)?.toDouble() ?? 0.0,
      currentExpectedCash: (json['current_expected_cash'] as num?)?.toDouble() ?? 0.0,
      operationsCount: json['operations_count'] as int? ?? list.length,
      operations: list
          .map((e) => CashOperation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        shiftId,
        openingCash,
        totalDeposits,
        totalWithdrawals,
        currentExpectedCash,
        operationsCount,
        operations,
      ];
}
