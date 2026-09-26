import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/pos/models/cash_operation.dart';

void main() {
  group('CashOperation Model Tests', () {
    test('CashOperation fromJson and toJson serialization roundtrip', () {
      final json = {
        'id': 10,
        'shift_id': 3,
        'user_id': 1,
        'user_name': 'Alice',
        'type': 'deposit',
        'amount': 500.0,
        'category': 'Разменная монета',
        'comment': 'Купюры по 50 и 100',
        'created_at': '2026-09-26T14:00:00.000',
        'client_uuid': 'uuid-1234',
      };

      final op = CashOperation.fromJson(json);

      expect(op.id, 10);
      expect(op.shiftId, 3);
      expect(op.userId, 1);
      expect(op.userName, 'Alice');
      expect(op.type, CashOpType.deposit);
      expect(op.amount, 500.0);
      expect(op.category, 'Разменная монета');
      expect(op.comment, 'Купюры по 50 и 100');
      expect(op.clientUuid, 'uuid-1234');

      final serialized = op.toJson();
      expect(serialized['type'], 'deposit');
      expect(serialized['amount'], 500.0);
      expect(serialized['category'], 'Разменная монета');
    });

    test('CashOperationsSummary fromJson parses operations array', () {
      final json = {
        'shift_id': 5,
        'opening_cash': 1000.0,
        'total_deposits': 500.0,
        'total_withdrawals': 300.0,
        'current_expected_cash': 1200.0,
        'operations_count': 2,
        'operations': [
          {
            'id': 1,
            'shift_id': 5,
            'user_id': 1,
            'type': 'deposit',
            'amount': 500.0,
            'category': 'Довнесение',
          },
          {
            'id': 2,
            'shift_id': 5,
            'user_id': 1,
            'type': 'withdrawal',
            'amount': 300.0,
            'category': 'Инкассация',
          },
        ],
      };

      final summary = CashOperationsSummary.fromJson(json);

      expect(summary.shiftId, 5);
      expect(summary.openingCash, 1000.0);
      expect(summary.totalDeposits, 500.0);
      expect(summary.totalWithdrawals, 300.0);
      expect(summary.currentExpectedCash, 1200.0);
      expect(summary.operations.length, 2);
      expect(summary.operations[0].type, CashOpType.deposit);
      expect(summary.operations[1].type, CashOpType.withdrawal);
    });
  });
}
