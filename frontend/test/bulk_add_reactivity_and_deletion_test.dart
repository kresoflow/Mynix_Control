// ==============================================================================
// ТЕСТЫ: Реактивная валидация дубликатов Bulk Add и Массовое удаление каталога
// ДОМЕН: test/bulk_add_reactivity_and_deletion_test.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_add_controller.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_add_list_widget.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_deletion_dialogs.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/pos/repository/menu_repository.dart';

class _FakeMenuRepo extends MenuRepository {
  _FakeMenuRepo() : super(Dio());
  @override
  Future<List<MenuItem>> getMenuItems() async => [];
}

class _TrackingMenuBloc extends MenuBloc {
  List<MenuEvent> dispatchedEvents = [];

  _TrackingMenuBloc() : super(_FakeMenuRepo()) {
    emit(const MenuLoaded(items: []));
  }

  @override
  void add(MenuEvent event) {
    dispatchedEvents.add(event);
    super.add(event);
  }
}

class _FakeInventoryRepo extends InventoryRepository {
  _FakeInventoryRepo() : super(Dio());
}

class _TrackingCategoryBloc extends CategoryBloc {
  List<CategoryEvent> dispatchedEvents = [];

  _TrackingCategoryBloc() : super(_FakeInventoryRepo()) {
    emit(const CategoryLoaded(categories: []));
  }

  @override
  void add(CategoryEvent event) {
    dispatchedEvents.add(event);
    super.add(event);
  }
}

void main() {
  group('1. BulkAddController Reactivity Invariants', () {
    test('Text changes in row controllers notify BulkAddController listeners', () {
      final controller = BulkAddController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.addRow(1); // Retail row
      expect(notifyCount, 1);

      final row = controller.retailRows.first;
      row.nameController.text = 'Оби арзон';
      expect(notifyCount, greaterThan(1));

      final lastCount = notifyCount;
      row.flavorController.text = 'Лимон';
      expect(notifyCount, greaterThan(lastCount));

      controller.dispose();
    });
  });

  group('2. Cross-Row Duplicate Reactivity (Eliminating Sticky Warning)', () {
    testWidgets('Editing or removing duplicate row reactively updates leader row warning', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = BulkAddController();
      final menuBloc = _TrackingMenuBloc();

      // Add 2 retail rows
      controller.addRow(1);
      controller.addRow(1);

      controller.retailRows[0].nameController.text = 'Оби арзон';
      controller.retailRows[1].nameController.text = 'Оби арзон';

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MenuBloc>.value(
            value: menuBloc,
            child: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 600,
                child: BulkAddListWidget(
                  tabIndex: 1,
                  controller: controller,
                  dishRows: controller.dishRows,
                  retailRows: controller.retailRows,
                  ingredientRows: controller.ingredientRows,
                  categoryRows: controller.categoryRows,
                  onAddRow: () => controller.addRow(1),
                  onDuplicateRow: (i) => controller.duplicateRow(1, i),
                  onRemoveRow: (i) => controller.removeRow(1, i),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially both rows must show duplicate warning
      expect(find.text('Дубликат товара и вкуса в строках ввода'), findsNWidgets(2));

      // User modifies Row 2 from 'Оби арзон' to 'Оби арзо' (unique)
      controller.retailRows[1].nameController.text = 'Оби арзо';
      await tester.pumpAndSettle();

      // BOTH Row 1 (leader) and Row 2 must have NO duplicate warning!
      expect(find.text('Дубликат товара и вкуса в строках ввода'), findsNothing);

      // User sets Row 2 back to duplicate
      controller.retailRows[1].nameController.text = 'Оби арзон';
      await tester.pumpAndSettle();
      expect(find.text('Дубликат товара и вкуса в строках ввода'), findsNWidgets(2));

      // User deletes Row 2 via controller.removeRow
      controller.removeRow(1, 1);
      await tester.pumpAndSettle();

      // Leader row (Row 0) must reactively clear duplicate warning without focus changes!
      expect(find.text('Дубликат товара и вкуса в строках ввода'), findsNothing);

      controller.dispose();
    });
  });

  group('3. Catalog Mass Deletion vs Archiving Modal Invariants', () {
    testWidgets('confirmDeleteSelected with isArchived: true shows hard delete and dispatches mode: hard', (tester) async {
      final menuBloc = _TrackingMenuBloc();
      final catBloc = _TrackingCategoryBloc();
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<MenuBloc>.value(value: menuBloc),
              BlocProvider<CategoryBloc>.value(value: catBloc),
            ],
            child: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => CatalogDeletionDialogs.confirmDeleteSelected(
                    context: ctx,
                    selectedItems: {10},
                    selectedCategories: {20},
                    isArchived: true,
                    onCleared: () => cleared = true,
                  ),
                  child: const Text('Delete Selected'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Selected'));
      await tester.pumpAndSettle();

      // Dialog title must say 'Удаление навсегда'
      expect(find.text('Удаление навсегда'), findsOneWidget);
      expect(find.text('Окончательно удалить выбранные элементы (2 шт.) из базы данных?\nЭто действие необратимо и возможно только если по ним нет истории продаж и склада.'), findsOneWidget);

      // Confirm hard delete
      final confirmBtn = find.text('Удалить навсегда');
      await tester.tap(confirmBtn.last);
      await tester.pumpAndSettle();

      expect(cleared, isTrue);

      // Verify MenuBloc received DeleteMenuItemsBulk with mode: 'hard'
      final menuEvents = menuBloc.dispatchedEvents.whereType<DeleteMenuItemsBulk>().toList();
      expect(menuEvents.length, 1);
      expect(menuEvents.first.ids, [10]);
      expect(menuEvents.first.mode, 'hard');

      // Verify CategoryBloc received DeleteCategoriesBulk with mode: 'hard'
      final catEvents = catBloc.dispatchedEvents.whereType<DeleteCategoriesBulk>().toList();
      expect(catEvents.length, 1);
      expect(catEvents.first.ids, [20]);
      expect(catEvents.first.mode, 'hard');
    });

    testWidgets('confirmDeleteSelected with isArchived: false shows soft archive and dispatches mode: soft', (tester) async {
      final menuBloc = _TrackingMenuBloc();
      final catBloc = _TrackingCategoryBloc();
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<MenuBloc>.value(value: menuBloc),
              BlocProvider<CategoryBloc>.value(value: catBloc),
            ],
            child: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => CatalogDeletionDialogs.confirmDeleteSelected(
                    context: ctx,
                    selectedItems: {15},
                    selectedCategories: {},
                    isArchived: false,
                    onCleared: () => cleared = true,
                  ),
                  child: const Text('Archive Selected'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Archive Selected'));
      await tester.pumpAndSettle();

      // Dialog title must say 'Массовая архивация'
      expect(find.text('Массовая архивация'), findsOneWidget);
      expect(find.text('Переместить выбранные элементы (1 шт.) в архив?\nОни будут скрыты из кассы, но сохранятся в архиве.'), findsOneWidget);

      // Confirm soft archive
      final confirmBtn = find.text('Архивировать');
      await tester.tap(confirmBtn.last);
      await tester.pumpAndSettle();

      expect(cleared, isTrue);

      final menuEvents = menuBloc.dispatchedEvents.whereType<DeleteMenuItemsBulk>().toList();
      expect(menuEvents.length, 1);
      expect(menuEvents.first.ids, [15]);
      expect(menuEvents.first.mode, 'soft');
    });
  });
}
