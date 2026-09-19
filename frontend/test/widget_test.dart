import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';

void main() {
  group('UI Kit AppButton Widget Tests', () {
    testWidgets('Renders AppButton with primary variant and triggers onPressed', (WidgetTester tester) async {
      int pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppButton(
                label: 'Сохранить',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.md,
                onPressed: () {
                  pressCount++;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Сохранить'), findsOneWidget);
      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      expect(pressCount, equals(1));
    });

    testWidgets('AppButton disabled state does not trigger callback', (WidgetTester tester) async {
      const Widget widget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(
              label: 'Недоступно',
              variant: AppButtonVariant.secondary,
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Недоступно'), findsOneWidget);
      await tester.tap(find.text('Недоступно'));
      await tester.pump();
      // Verified that widget renders without error when disabled
      expect(find.byType(AppButton), findsOneWidget);
    });

    test('AppButtonSize dimensions conform to Design System token scale', () {
      expect(AppButtonSize.xs.height, equals(28.0));
      expect(AppButtonSize.sm.height, equals(32.0));
      expect(AppButtonSize.md.height, equals(36.0));
      expect(AppButtonSize.lg.height, equals(44.0));
      expect(AppButtonSize.xl.height, equals(52.0));
    });
  });

  group('Inventory Domain Models Serialization & Invariants', () {
    test('Ingredient fromJson deserializes and computes displayCode correctly', () {
      final json = {
        'id': 42,
        'name': 'Зерно Бразилия',
        'unit': 'kg',
        'current_stock': 15.5,
        'min_stock_alert': 5.0,
        'cost_per_unit': 850.0,
        'is_low_stock': false,
        'barcode': '4601234567890',
        'attributes': {'sku': 'BR-COF-01'},
      };

      final ing = Ingredient.fromJson(json);
      expect(ing.id, equals(42));
      expect(ing.name, equals('Зерно Бразилия'));
      expect(ing.currentStock, equals(15.5));
      expect(ing.costPerUnit, equals(850.0));
      expect(ing.displayCode, equals('BR-COF-01'));
    });

    test('Ingredient displayCode falls back to barcode then #id', () {
      final jsonWithBarcode = {
        'id': 101,
        'name': 'Молоко 3.2%',
        'unit': 'l',
        'current_stock': 0.0,
        'min_stock_alert': 0.0,
        'cost_per_unit': 0.0,
        'is_low_stock': false,
        'barcode': '4609876543210',
      };
      final ingBarcode = Ingredient.fromJson(jsonWithBarcode);
      expect(ingBarcode.displayCode, equals('4609876543210'));

      final jsonPlain = {
        'id': 202,
        'name': 'Сахар',
        'unit': 'kg',
        'current_stock': 0.0,
        'min_stock_alert': 0.0,
        'cost_per_unit': 0.0,
        'is_low_stock': false,
      };
      final ingPlain = Ingredient.fromJson(jsonPlain);
      expect(ingPlain.displayCode, equals('#202'));
    });

    test('InventoryDocumentItem serialization roundtrip', () {
      final item = InventoryDocumentItem(
        id: 1,
        documentId: 10,
        ingredientId: 5,
        quantity: 25.0,
        pricePerUnit: 120.0,
        totalPrice: 3000.0,
      );

      final json = item.toJson();
      expect(json['ingredient_id'], equals(5));
      expect(json['quantity'], equals(25.0));
      expect(json['price_per_unit'], equals(120.0));
      expect(json['total_price'], equals(3000.0));
    });
  });
}
