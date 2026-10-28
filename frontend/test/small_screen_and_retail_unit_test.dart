// ==============================================================================
// ТЕСТЫ: Адаптивность малых экранов и единицы измерения ритейл-товаров
// ДОМЕН: test/small_screen_and_retail_unit_test.dart
// ==============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_empty_state.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/create_retail_submit_helper.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/pos/view/widgets/components/pos_menu_grid_view.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

class _FakeInventoryRepo extends InventoryRepository {
  _FakeInventoryRepo() : super(Dio());
}

class _FakeCategoryBloc extends CategoryBloc {
  _FakeCategoryBloc() : super(_FakeInventoryRepo()) {
    emit(const CategoryLoaded(categories: []));
  }
}

void main() {
  group('1. Small Screen Constraints & Stock Empty State', () {
    testWidgets('StockEmptyState does not overflow in low-height container (220px)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 220,
              width: 400,
              child: StockEmptyState(
                searchQuery: '',
                filter: 'raw',
                onReset: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Нет позиций в выбранной категории'), findsOneWidget);
      expect(find.text('Сбросить фильтры и поиск'), findsOneWidget);
    });

    testWidgets('PosMenuGridView adapts columns to narrow width without squeezing cards', (tester) async {
      final posSettingsCubit = PosSettingsCubit();

      const dummyItem = MenuItem(
        id: 1,
        name: 'Оби Кулоб|TYPE|retail',
        price: 10.0,
        categoryId: '1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<CategoryBloc>(create: (_) => _FakeCategoryBloc()),
                BlocProvider<PosSettingsCubit>.value(value: posSettingsCubit),
                BlocProvider<SettingsBloc>(create: (_) => SettingsBloc()),
              ],
              child: SizedBox(
                width: 380,
                height: 600,
                child: PosMenuGridView(
                  categories: const [],
                  items: const [dummyItem],
                  posSettings: posSettingsCubit.state,
                  onCategoryTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final grid = tester.widget<GridView>(gridFinder);
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // На доступной ширине 380px (< 420px) колонок должно быть 2, а не 4 или 5
      expect(delegate.crossAxisCount, equals(2));
    });
  });

  group('2. Retail Product Unit & Attributes Invariants', () {
    test('MenuItem attributes getter parses JSON correctly and returns unit', () {
      final item = MenuItem(
        id: 42,
        name: 'Оби Кулоб|TYPE|retail',
        price: 10.0,
        categoryId: '5',
        attributesJson: jsonEncode({
          'unit': 'l',
          'volume': '1 л',
          'flavor': 'Лимон',
        }),
      );

      expect(item.attributes, isNotNull);
      expect(item.attributes!['unit'], equals('l'));
      expect(item.attributes!['volume'], equals('1 л'));
      expect(item.attributes!['flavor'], equals('Лимон'));
    });

    test('CreateRetailSubmitHelper buildPayload preserves selectedUnit', () {
      final payload = CreateRetailSubmitHelper.buildPayload(
        name: 'Оби Кулоб',
        basePrice: 10.0,
        baseBarcode: '12345678',
        flavor: null,
        rawVolume: '1',
        selectedUnit: 'l',
        selectedIcon: null,
        variations: const [],
      );

      expect(payload.attributes, isNotNull);
      expect(payload.attributes!['unit'], equals('l'));
      expect(payload.attributes!['volume'], equals('1 л'));
    });

    test('CreateRetailSubmitHelper buildPayload with variations preserves selectedUnit', () {
      final payload = CreateRetailSubmitHelper.buildPayload(
        name: 'Оби Кулоб',
        basePrice: 5.0,
        baseBarcode: null,
        flavor: null,
        rawVolume: null,
        selectedUnit: 'ml',
        selectedIcon: null,
        variations: [
          {'name': '250', 'price': 5.0, 'barcode': '111', 'unit': 'ml'},
          {'name': '500', 'price': 8.0, 'barcode': '222', 'unit': 'ml'},
        ],
      );

      expect(payload.attributes, isNotNull);
      expect(payload.attributes!['unit'], equals('ml'));
      final vars = payload.attributes!['variations'] as List;
      expect(vars.length, equals(2));
      expect(vars[0]['unit'], equals('ml'));
      expect(vars[1]['unit'], equals('ml'));
    });
  });

  group('3. Poka-Yoke & Dirty Detection Invariants', () {
    test('RetailProductSnapshot isDirty returns false when variations product opened without edits', () {
      final initialVars = [
        {'id': 101, 'name': '0.5 л', 'price': 5.0, 'barcode': null, 'unit': 'pcs'},
        {'id': 102, 'name': '1 л', 'price': 10.0, 'barcode': null, 'unit': 'pcs'},
      ];

      final snapshot = RetailProductSnapshot(
        name: 'Оби Арзонак',
        flavor: '',
        volume: '',
        sortOrder: '2',
        price: '',
        barcode: '',
        categoryId: 1,
        unit: 'pcs',
        icon: null,
        variationsJson: jsonEncode(initialVars),
      );

      // Без изменений — Poka-Yoke НЕ должен срабатывать
      final isDirty = snapshot.isDirty(
        isEditing: true,
        currentName: 'Оби Арзонак',
        currentFlavor: '',
        currentVolume: '',
        currentSortOrder: '2',
        currentPrice: '',
        currentBarcode: '',
        currentCategoryId: 1,
        currentUnit: 'pcs',
        currentIcon: null,
        currentVariations: initialVars,
      );

      expect(isDirty, isFalse);
    });

    test('RetailProductSnapshot isDirty returns true when a variation price is modified', () {
      final initialVars = [
        {'id': 101, 'name': '0.5 л', 'price': 5.0, 'barcode': null, 'unit': 'pcs'},
      ];

      final snapshot = RetailProductSnapshot(
        name: 'Оби Арзонак',
        flavor: '',
        volume: '',
        sortOrder: '2',
        price: '',
        barcode: '',
        categoryId: 1,
        unit: 'pcs',
        icon: null,
        variationsJson: jsonEncode(initialVars),
      );

      final modifiedVars = [
        {'id': 101, 'name': '0.5 л', 'price': 6.0, 'barcode': null, 'unit': 'pcs'},
      ];

      final isDirty = snapshot.isDirty(
        isEditing: true,
        currentName: 'Оби Арзонак',
        currentFlavor: '',
        currentVolume: '',
        currentSortOrder: '2',
        currentPrice: '',
        currentBarcode: '',
        currentCategoryId: 1,
        currentUnit: 'pcs',
        currentIcon: null,
        currentVariations: modifiedVars,
      );

      expect(isDirty, isTrue);
    });
  });
}
