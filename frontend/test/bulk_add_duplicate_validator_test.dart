// ==============================================================================
// ТЕСТЫ: Валидатор коллизий пакетного добавления номенклатуры (Bulk Add)
// ДОМЕН: test/bulk_add_duplicate_validator_test.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_add_duplicate_validator.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/dish_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/retail_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/ingredient_row.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/category_row.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/pos/repository/menu_repository.dart';

class _FakeMenuRepo extends MenuRepository {
  _FakeMenuRepo() : super(Dio());
  @override
  Future<List<MenuItem>> getMenuItems() async => [];
}

class _TestMenuBloc extends MenuBloc {
  _TestMenuBloc(List<MenuItem> initialItems) : super(_FakeMenuRepo()) {
    emit(MenuLoaded(items: initialItems));
  }
}

void main() {
  group('BulkAddDuplicateValidator In-Batch Tests', () {
    testWidgets('Detects in-batch duplicate retail rows with same name, flavor, and volume', (tester) async {
      final r1 = RetailRowData(name: 'Фанта', flavor: 'Слайм', volume: '1 л');
      final r2 = RetailRowData(name: 'Фанта', flavor: 'Слайм', volume: '1 л');

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MenuBloc>(
            create: (_) => _TestMenuBloc([]),
            child: Builder(
              builder: (context) {
                final warning1 = BulkAddDuplicateValidator.checkDuplicate(
                  context: context,
                  tabIndex: 1,
                  index: 0,
                  dishRows: [],
                  retailRows: [r1, r2],
                  ingredientRows: [],
                  categoryRows: [],
                );
                expect(warning1, isNotNull);
                expect(warning1, contains('Дубликат товара и вкуса в строках ввода'));

                final warning2 = BulkAddDuplicateValidator.checkDuplicate(
                  context: context,
                  tabIndex: 1,
                  index: 1,
                  dishRows: [],
                  retailRows: [r1, r2],
                  ingredientRows: [],
                  categoryRows: [],
                );
                expect(warning2, isNotNull);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Detects in-batch duplicate barcode in retail rows', (tester) async {
      final r1 = RetailRowData(name: 'Фанта 1', barcode: '460123456');
      final r2 = RetailRowData(name: 'Фанта 2', barcode: '460123456');

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MenuBloc>(
            create: (_) => _TestMenuBloc([]),
            child: Builder(
              builder: (context) {
                final warning = BulkAddDuplicateValidator.checkDuplicate(
                  context: context,
                  tabIndex: 1,
                  index: 1,
                  dishRows: [],
                  retailRows: [r1, r2],
                  ingredientRows: [],
                  categoryRows: [],
                );
                expect(warning, isNotNull);
                expect(warning, contains('Дубликат штрихкода в строках массового ввода'));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('BulkAddDuplicateValidator Against-Catalog Tests (Core Engine Integration)', () {
    testWidgets('Correctly detects duplicate when single retail product matches catalog variant (Фанта Слайм 1 л)', (tester) async {
      final existingCatalog = [
        const MenuItem(
          id: 101,
          name: 'Фанта|TYPE|retail',
          price: 30,
          categoryId: '2',
          attributesJson: '{"flavor": "Слайм", "variations": [{"name": "Фанта Слайм 1 л", "price": 30}]}',
        ),
      ];

      // Одиночный товар в массовом вводе
      final r1 = RetailRowData(name: 'Фанта', flavor: 'Слайм', volume: '1');

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MenuBloc>(
            create: (_) => _TestMenuBloc(existingCatalog),
            child: Builder(
              builder: (context) {
                final warning = BulkAddDuplicateValidator.checkDuplicate(
                  context: context,
                  tabIndex: 1,
                  index: 0,
                  dishRows: [],
                  retailRows: [r1],
                  ingredientRows: [],
                  categoryRows: [],
                );

                expect(warning, isNotNull, reason: 'Верификатор обязан находить дубликат даже если в таблице всего 1 строка');
                expect(warning, contains('уже существует'));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Does not flag duplicate when flavor or volume differs', (tester) async {
      final existingCatalog = [
        const MenuItem(
          id: 101,
          name: 'Фанта|TYPE|retail',
          price: 30,
          categoryId: '2',
          attributesJson: '{"flavor": "Слайм", "variations": [{"name": "Фанта Слайм 1 л", "price": 30}]}',
        ),
      ];

      // Другой вкус
      final rDiffFlavor = RetailRowData(name: 'Фанта', flavor: 'Апельсин', volume: '1');
      // Другой объем
      final rDiffVol = RetailRowData(name: 'Фанта', flavor: 'Слайм', volume: '0.5');

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MenuBloc>(
            create: (_) => _TestMenuBloc(existingCatalog),
            child: Builder(
              builder: (context) {
                final warning1 = BulkAddDuplicateValidator.checkDuplicate(
                  context: context,
                  tabIndex: 1,
                  index: 0,
                  dishRows: [],
                  retailRows: [rDiffFlavor],
                  ingredientRows: [],
                  categoryRows: [],
                );
                expect(warning1, isNull);

                final warning2 = BulkAddDuplicateValidator.checkDuplicate(
                  context: context,
                  tabIndex: 1,
                  index: 0,
                  dishRows: [],
                  retailRows: [rDiffVol],
                  ingredientRows: [],
                  categoryRows: [],
                );
                expect(warning2, isNull);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });
}
