// ==============================================================================
// ТЕСТЫ: Адаптивность малых экранов и единицы измерения ритейл-товаров
// ДОМЕН: test/small_screen_and_retail_unit_test.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/stock/stock_empty_state.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/create_retail_submit_helper.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/retail_product_snapshot.dart';
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

      expect(tester.takeException(), isNull);
      expect(find.text('Оби Кулоб'), findsOneWidget);
    });
  });

  group('2. UnitFormatter Parsing & Formatting (Stock vs Display)', () {
    test('UnitFormatter.parseVolumeAndUnit parses various user inputs', () {
      final p1 = UnitFormatter.parseVolumeAndUnit('1 л');
      expect(p1.value, equals('1'));
      expect(p1.unit, equals('l'));

      final p2 = UnitFormatter.parseVolumeAndUnit('0.5л');
      expect(p2.value, equals('0.5'));
      expect(p2.unit, equals('l'));

      final p3 = UnitFormatter.parseVolumeAndUnit('250 мл');
      expect(p3.value, equals('250'));
      expect(p3.unit, equals('ml'));

      final p4 = UnitFormatter.parseVolumeAndUnit('100г');
      expect(p4.value, equals('100'));
      expect(p4.unit, equals('g'));

      final p5 = UnitFormatter.parseVolumeAndUnit('1.5', 'l');
      expect(p5.value, equals('1.5'));
      expect(p5.unit, equals('l'));
    });

    test('UnitFormatter.formatVolumeString produces clean display string', () {
      expect(UnitFormatter.formatVolumeString('1', 'l'), equals('1 л'));
      expect(UnitFormatter.formatVolumeString('0.5', 'l'), equals('0.5 л'));
      expect(UnitFormatter.formatVolumeString('250', 'ml'), equals('250 мл'));
      expect(UnitFormatter.formatVolumeString('100', 'g'), equals('100 г'));
    });
  });

  group('3. CreateRetailSubmitHelper (Separated Stock and Display Units)', () {
    test('buildPayload separates stock_unit (pcs) and display_unit (l)', () {
      final payload = CreateRetailSubmitHelper.buildPayload(
        name: 'Вода М',
        basePrice: 10.0,
        baseBarcode: '12345678',
        flavor: null,
        rawVolume: '1',
        stockUnit: 'pcs',
        displayUnit: 'l',
        selectedIcon: null,
        variations: const [],
      );

      expect(payload.attributes, isNotNull);
      expect(payload.attributes!['stock_unit'], equals('pcs'));
      expect(payload.attributes!['display_unit'], equals('l'));
      expect(payload.attributes!['unit'], equals('pcs')); // для склада
      expect(payload.attributes!['volume'], equals('1 л')); // для витрины
      expect(payload.attributes!['volume_val'], equals('1'));
    });

    test('buildPayload with variations assigns stockUnit to child items and formats names', () {
      final payload = CreateRetailSubmitHelper.buildPayload(
        name: 'Оби Арзонак',
        basePrice: 5.0,
        baseBarcode: null,
        flavor: null,
        rawVolume: null,
        stockUnit: 'pcs',
        displayUnit: 'l',
        selectedIcon: null,
        variations: [
          {'name': '0.5', 'price': 5.0, 'barcode': '111', 'unit': 'pcs'},
          {'name': '1', 'price': 10.0, 'barcode': '222', 'unit': 'pcs'},
        ],
      );

      expect(payload.attributes, isNotNull);
      expect(payload.attributes!['stock_unit'], equals('pcs'));
      expect(payload.attributes!['display_unit'], equals('l'));
      expect(payload.attributes!['unit'], equals('pcs'));
      final vars = payload.attributes!['variations'] as List;
      expect(vars.length, equals(2));
      expect(vars[0]['unit'], equals('pcs'));
      expect(vars[0]['name'], equals('Оби Арзонак 0.5 л'));
      expect(vars[1]['unit'], equals('pcs'));
      expect(vars[1]['name'], equals('Оби Арзонак 1 л'));
    });
  });

  group('4. Poka-Yoke & Dirty Detection with Dual Units', () {
    test('RetailProductSnapshot isDirty returns false when variations product opened without edits', () {
      final initialVars = [
        {'id': 101, 'name': '0.5', 'price': 5.0, 'barcode': null, 'unit': 'pcs'},
        {'id': 102, 'name': '1', 'price': 10.0, 'barcode': null, 'unit': 'pcs'},
      ];

      const snapshot = RetailProductSnapshot(
        name: 'Оби Арзонак',
        flavor: '',
        volume: '',
        sortOrder: '2',
        price: '',
        barcode: '',
        categoryId: 1,
        stockUnit: 'pcs',
        displayUnit: 'l',
        icon: null,
        variationsJson: '[{"id":101,"name":"0.5","price":5.0,"barcode":null,"unit":"pcs"},{"id":102,"name":"1","price":10.0,"barcode":null,"unit":"pcs"}]',
      );

      final isDirty = snapshot.isDirty(
        isEditing: true,
        currentName: 'Оби Арзонак',
        currentFlavor: '',
        currentVolume: '',
        currentSortOrder: '2',
        currentPrice: '',
        currentBarcode: '',
        currentCategoryId: 1,
        currentStockUnit: 'pcs',
        currentDisplayUnit: 'l',
        currentIcon: null,
        currentVariations: initialVars,
      );

      expect(isDirty, isFalse);
    });

    test('RetailProductSnapshot isDirty returns true when displayUnit changed', () {
      const snapshot = RetailProductSnapshot(
        name: 'Вода М',
        flavor: '',
        volume: '1',
        sortOrder: '1',
        price: '10',
        barcode: '',
        categoryId: 1,
        stockUnit: 'pcs',
        displayUnit: 'l',
        icon: null,
        variationsJson: '[]',
      );

      final isDirty = snapshot.isDirty(
        isEditing: true,
        currentName: 'Вода М',
        currentFlavor: '',
        currentVolume: '1',
        currentSortOrder: '1',
        currentPrice: '10',
        currentBarcode: '',
        currentCategoryId: 1,
        currentStockUnit: 'pcs',
        currentDisplayUnit: 'ml', // изменена единица тары
        currentIcon: null,
        currentVariations: const [],
      );

      expect(isDirty, isTrue);
    });
  });
}
