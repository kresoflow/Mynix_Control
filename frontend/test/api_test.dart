import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/inventory/models/supplier.dart';

void main() {
  group('Supplier API & Domain Model Serialization', () {
    test('Supplier fromJson correctly parses balance and debt invariants', () {
      final json = {
        'id': 10,
        'name': 'ООО HoReCa Снабжение',
        'contact_info': '+996 555 001122',
        'is_active': true,
        'balance': -18500.0,
      };

      final supplier = Supplier.fromJson(json);
      expect(supplier.id, equals(10));
      expect(supplier.name, equals('ООО HoReCa Снабжение'));
      expect(supplier.balance, equals(-18500.0));
      expect(supplier.isActive, isTrue);
    });

    test('Supplier toJson produces exact payload for API updates', () {
      final supplier = Supplier(
        id: 15,
        name: 'Новый Поставщик',
        contactInfo: 'supplier@mynix.local',
        isActive: true,
        balance: 0.0,
      );

      final json = supplier.toJson();
      expect(json['id'], equals(15));
      expect(json['name'], equals('Новый Поставщик'));
      expect(json['contact_info'], equals('supplier@mynix.local'));
      expect(json['balance'], equals(0.0));
    });
  });
}
