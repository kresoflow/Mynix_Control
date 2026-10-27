// ==============================================================================
// Title: PosOrderPaymentAccountTest
// Path: frontend/test/pos_order_payment_account_test.dart
// Description: Модульные тесты форматирования способов оплаты и счетов в чеках.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/orders/models/pos_order.dart';

void main() {
  group('PosOrder Payment Method & Account Tests', () {
    test('Оплата наличными отображается как «Наличные»', () {
      final order = PosOrder(
        id: 1,
        orderNumber: 101,
        status: 'completed',
        paymentMethod: 'cash',
        paymentAccount: 'cash',
        total: 50.0,
        createdAt: DateTime.now(),
        items: const [],
      );

      expect(order.paymentMethodLabel, equals('Наличные'));
    });

    test('Оплата через DC отображается как «Перевод (DC)»', () {
      final order = PosOrder(
        id: 2,
        orderNumber: 102,
        status: 'completed',
        paymentMethod: 'transfer',
        paymentAccount: 'dc',
        total: 100.0,
        createdAt: DateTime.now(),
        items: const [],
      );

      expect(order.paymentMethodLabel, equals('Перевод (DC)'));
    });

    test('Оплата через Алиф отображается как «Перевод (Алиф)»', () {
      final order = PosOrder(
        id: 3,
        orderNumber: 103,
        status: 'completed',
        paymentMethod: 'transfer',
        paymentAccount: 'alif',
        total: 120.0,
        createdAt: DateTime.now(),
        items: const [],
      );

      expect(order.paymentMethodLabel, equals('Перевод (Алиф)'));
    });

    test('Оплата через Спитамен отображается как «Перевод (Спитамен)»', () {
      final order = PosOrder(
        id: 4,
        orderNumber: 104,
        status: 'completed',
        paymentMethod: 'transfer',
        paymentAccount: 'spitamen',
        total: 80.0,
        createdAt: DateTime.now(),
        items: const [],
      );

      expect(order.paymentMethodLabel, equals('Перевод (Спитамен)'));
    });

    test('Оплата через Другой отображается как «Перевод (Другой)»', () {
      final order = PosOrder(
        id: 5,
        orderNumber: 105,
        status: 'completed',
        paymentMethod: 'transfer',
        paymentAccount: 'other',
        total: 90.0,
        createdAt: DateTime.now(),
        items: const [],
      );

      expect(order.paymentMethodLabel, equals('Перевод (Другой)'));
    });

    test('Устаревшие чеки без paymentAccount считывают счет из note', () {
      final order = PosOrder(
        id: 6,
        orderNumber: 106,
        status: 'completed',
        paymentMethod: 'transfer',
        note: 'Перевод: DC',
        total: 15.0,
        createdAt: DateTime.now(),
        items: const [],
      );

      expect(order.paymentMethodLabel, equals('Перевод (DC)'));
    });

    test('Устаревшие чеки столиков transfer_spitamen отображают счет', () {
      final order = PosOrder(
        id: 7,
        orderNumber: 107,
        status: 'completed',
        paymentMethod: 'transfer_spitamen',
        total: 200.0,
        createdAt: DateTime.now(),
        items: const [],
      );

      expect(order.paymentMethodLabel, equals('Перевод (Спитамен)'));
    });
  });
}
