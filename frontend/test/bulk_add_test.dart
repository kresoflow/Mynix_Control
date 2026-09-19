import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/pos/repository/menu_repository.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_add_controller.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_add_footer.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_add_payload_builder.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/dish_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/ingredient_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/retail_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/category_row.dart';

class _MockDio extends Fake implements Dio {}

class _TrackingMenuRepository extends MenuRepository {
  int bulkMenuItemsCallCount = 0;
  int bulkRetailProductsCallCount = 0;
  int getMenuItemsCallCount = 0;
  List<Map<String, dynamic>> lastMenuItemsPayload = [];
  List<Map<String, dynamic>> lastRetailProductsPayload = [];

  _TrackingMenuRepository() : super(_MockDio());

  @override
  Future<List<MenuItem>> getMenuItems() async {
    getMenuItemsCallCount++;
    return [
      const MenuItem(
        id: 1,
        name: 'Item 1',
        price: 100.0,
        categoryId: '1',
      ),
    ];
  }

  @override
  Future<List<dynamic>> createMenuItemsBulk(List<Map<String, dynamic>> items) async {
    bulkMenuItemsCallCount++;
    lastMenuItemsPayload = items;
    return items.map((e) => {'id': 100, ...e}).toList();
  }

  @override
  Future<List<dynamic>> createRetailProductsBulk(List<Map<String, dynamic>> items) async {
    bulkRetailProductsCallCount++;
    lastRetailProductsPayload = items;
    return items.map((e) => {'id': 200, ...e}).toList();
  }
}

void main() {
  group('Worker M2: Batch BLoC Events & Network Storm Elimination (R1)', () {
    test('MenuBloc processes CreateMenuItemsBulk in a single call and reloads menu once', () async {
      final repo = _TrackingMenuRepository();
      final bloc = MenuBloc(repo);

      final payload = [
        {'name': 'Бургер 1', 'price': 250.0, 'category_id': 1},
        {'name': 'Бургер 2', 'price': 300.0, 'category_id': 1},
      ];

      bloc.add(CreateMenuItemsBulk(items: payload));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<MenuLoading>(),
          isA<MenuLoaded>(),
        ]),
      );

      expect(repo.bulkMenuItemsCallCount, 1);
      expect(repo.lastMenuItemsPayload.length, 2);
      expect(repo.getMenuItemsCallCount, 1);
      await bloc.close();
    });

    test('MenuBloc processes CreateRetailProductsBulk in a single call and reloads menu once', () async {
      final repo = _TrackingMenuRepository();
      final bloc = MenuBloc(repo);

      final payload = [
        {'name': 'Кола 0.5', 'selling_price': 100.0, 'purchase_price': 50.0, 'initial_stock': 0.0},
        {'name': 'Фанта 0.5', 'selling_price': 100.0, 'purchase_price': 50.0, 'initial_stock': 0.0},
      ];

      bloc.add(CreateRetailProductsBulk(items: payload));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<MenuLoading>(),
          isA<MenuLoaded>(),
        ]),
      );

      expect(repo.bulkRetailProductsCallCount, 1);
      expect(repo.lastRetailProductsPayload.length, 2);
      expect(repo.getMenuItemsCallCount, 1);
      await bloc.close();
    });
  });

  group('Worker M2: Virtual Stock Removal (R2)', () {
    test('RetailRowData and buildRetailPayload strictly set initial_stock to 0.0', () {
      final row = RetailRowData(
        name: 'Сок Яблочный',
        sell: '120',
      );

      // Verify row has unique ID
      expect(row.id, isNotEmpty);

      final payload = buildRetailPayload(
        retailRows: [row],
        targetCategoryId: 5,
      );

      expect(payload.length, 1);
      expect(payload[0]['name'], 'Сок Яблочный');
      expect(payload[0]['selling_price'], 120.0);
      expect(payload[0]['purchase_price'], 0.0);
      expect(payload[0]['initial_stock'], 0.0);
      expect(payload[0]['category_id'], 5);
    });

    test('IngredientRowData and buildIngredientPayload strictly set initial_stock to 0.0', () {
      final row = IngredientRowData(
        name: 'Мука пшеничная',
        cost: '45',
        selectedUnit: 'kg',
      );

      // Verify row has unique ID
      expect(row.id, isNotEmpty);

      final payload = buildIngredientPayload(
        ingredientRows: [row],
        targetCategoryId: 3,
        ingredientCategories: [],
        existingIngredients: [],
      );

      expect(payload.length, 1);
      expect(payload[0]['name'], 'Мука пшеничная');
      expect(payload[0]['cost_per_unit'], 45.0);
      expect(payload[0]['initial_stock'], 0.0);
      expect(payload[0]['unit'], 'kg');
    });

    test('buildDishPayload formats dishes and variations correctly', () {
      final row = DishRowData(
        name: 'Пицца Маргарита',
        options: '25см, 30см',
        price: '400, 550',
      );

      expect(row.id, isNotEmpty);

      final payload = buildDishPayload(
        dishRows: [row],
        targetCategoryId: 2,
      );

      expect(payload.length, 1);
      expect(payload[0]['name'], 'Пицца Маргарита');
      expect(payload[0]['price'], 400.0);
      expect(payload[0]['category_id'], 2);
      expect(payload[0]['attributes']['variations'].length, 2);
    });
  });

  group('Worker M2: Keyboard Navigation & Row State Invariants (R3)', () {
    test('BulkAddController manages rows and generates stable focus nodes', () {
      final controller = BulkAddController();

      // Add dish row
      controller.addRow(0);
      expect(controller.dishRows.length, 1);
      expect(controller.dishRows[0].id, isNotEmpty);
      expect(controller.getLastFocusNode(0), isNotNull);

      // Duplicate dish row
      controller.duplicateRow(0, 0);
      expect(controller.dishRows.length, 2);
      expect(controller.dishRows[0].id, isNot(equals(controller.dishRows[1].id)));

      // Remove dish row
      controller.removeRow(0, 0);
      expect(controller.dishRows.length, 1);

      // Add retail row
      controller.addRow(1);
      expect(controller.retailRows.length, 1);
      expect(controller.retailRows[0].id, isNotEmpty);

      // Add ingredient row
      controller.addRow(2);
      expect(controller.ingredientRows.length, 1);
      expect(controller.ingredientRows[0].id, isNotEmpty);

      // Add category row
      controller.addRow(3);
      expect(controller.categoryRows.length, 1);
      expect(controller.categoryRows[0].id, isNotEmpty);

      controller.dispose();
    });

    test('DishRowData, RetailRowData, IngredientRowData, CategoryRowData clone with distinct IDs', () {
      final d1 = DishRowData(name: 'Dish');
      final d2 = d1.clone();
      expect(d1.id, isNot(equals(d2.id)));
      expect(d2.nameController.text, 'Dish');

      final r1 = RetailRowData(name: 'Retail');
      final r2 = r1.clone();
      expect(r1.id, isNot(equals(r2.id)));
      expect(r2.nameController.text, 'Retail');

      final i1 = IngredientRowData(name: 'Ing');
      final i2 = i1.clone();
      expect(i1.id, isNot(equals(i2.id)));
      expect(i2.nameController.text, 'Ing');

      final c1 = CategoryRowData();
      c1.nameController.text = 'Cat';
      final c2 = c1.clone();
      expect(c1.id, isNot(equals(c2.id)));
      expect(c2.nameController.text, 'Cat');
    });
  });

  group('Worker M2: UI Kit Compliance & Design System Tokens', () {
    testWidgets('BulkAddFooter renders AppPrimaryButton with AppButtonSize.lg', (tester) async {
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkAddFooter(onSaveAll: () => saved = true),
          ),
        ),
      );

      final buttonFinder = find.byType(AppPrimaryButton);
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<AppPrimaryButton>(buttonFinder);
      expect(button.label, 'Сохранить всё');
      expect(button.size, AppButtonSize.lg);

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(saved, isTrue);
    });
  });
}
