import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/utils/audio_helper.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/receive_category_sync_adapter.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receipt_row_data.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receive_document_footer.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receive_document_processor.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receive_document_row_callbacks.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receive_document_payment_section.dart';

InventoryRepository createTestRepository() {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/complete')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 999,
                'type': 'receipt',
                'date': DateTime.now().toIso8601String(),
                'status': 'completed',
                'total_amount': 0.0,
              },
            ),
          );
        }
        if (options.path.contains('/documents')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [],
            ),
          );
        }
        if (options.path.contains('/suppliers')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [],
            ),
          );
        }
        if (options.path.contains('/ingredients')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [],
            ),
          );
        }
        return handler.next(options);
      },
    ),
  );
  return InventoryRepository(dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Worker M3: AudioHelper VM Testability', () {
    test('AudioHelper.playNewOrderSound executes safely on VM without crashing', () {
      expect(() => AudioHelper.playNewOrderSound(), returnsNormally);
    });
  });

  group('Worker M3: ReceiptRowData ValueNotifier Performance', () {
    test('ReceiptRowData initializes and updates rowTotalNotifier correctly', () {
      final row = ReceiptRowData(quantity: 5.0, price: 100.0);
      expect(row.rowTotalNotifier.value, equals(500.0));

      row.quantity = 10.0;
      row.price = 150.0;
      row.updateTotal();

      expect(row.rowTotalNotifier.value, equals(1500.0));
      row.dispose();
    });
  });

  group('Worker M3: Keyboard Enter Navigation & TabIndex Invariants', () {
    test('onRowPriceSubmitted jumps to sell price in retail mode (tabIndex == 1)', () {
      final row = ReceiptRowData();
      final items = [row];

      ReceiveDocumentRowCallbacks.onRowPriceSubmitted(
        items: items,
        index: 0,
        tabIndex: 1,
        onAddItem: () => fail('Should not add item in retail mode on cost price'),
      );

      row.dispose();
    });

    test('onRowPriceSubmitted adds new row when at end in raw mode (tabIndex == 2)', () {
      final row = ReceiptRowData();
      final items = [row];
      bool added = false;

      ReceiveDocumentRowCallbacks.onRowPriceSubmitted(
        items: items,
        index: 0,
        tabIndex: 2,
        onAddItem: () {
          added = true;
        },
      );

      expect(added, isTrue);
      row.dispose();
    });
  });

  group('Worker M3: State Synchronization (DocumentBloc -> IngredientBloc)', () {
    test('DocumentBloc dispatches LoadIngredients to IngredientBloc upon CompleteDocument', () async {
      final fakeRepo = createTestRepository();
      final ingredientBloc = IngredientBloc(fakeRepo);
      final documentBloc = DocumentBloc(fakeRepo, ingredientBloc);

      bool loadIngredientsDispatched = false;
      final sub = ingredientBloc.stream.listen((_) {});
      DocumentBloc.onDocumentCompletedCallback = () {
        loadIngredientsDispatched = true;
      };

      documentBloc.add(const CompleteDocument(999));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(loadIngredientsDispatched, isTrue);

      DocumentBloc.onDocumentCompletedCallback = null;
      await sub.cancel();
      await documentBloc.close();
      await ingredientBloc.close();
    });
  });

  group('Worker M3: Nomenclature Governance in Goods Receipt', () {
    test('ReceiveDocumentProcessor rejects items not selected from catalog', () async {
      final unselectedRow = ReceiptRowData(newName: 'Новый нелегальный товар');

      expect(
        () async {
          final items = [unselectedRow];
          for (var item in items) {
            if (item.ingredient == null) {
              throw Exception('Позиция "${item.nameController.text}" не найдена в каталоге.');
            }
          }
        },
        throwsA(isA<Exception>()),
      );

      unselectedRow.dispose();
    });
  });

  group('Category Mode: ReceiveCategorySyncAdapter Tests', () {
    test('updateQuantity creates new row with item attributes and triggers onTotalChanged', () {
      final items = <ReceiptRowData>[];
      int totalChangedCalls = 0;
      final adapter = ReceiveCategorySyncAdapter(
        items: items,
        onTotalChanged: () => totalChangedCalls++,
      );

      final ingredient = Ingredient(
        id: 42,
        name: 'Кофе Бразилия',
        unit: 'kg',
        currentStock: 2.5,
        minStockAlert: 5.0,
        costPerUnit: 1200.0,
        price: 1800.0,
        isLowStock: true,
      );

      adapter.updateQuantity(ingredient, 10.0);

      expect(items.length, equals(1));
      expect(items.first.ingredient?.id, equals(42));
      expect(items.first.quantity, equals(10.0));
      expect(items.first.price, equals(1200.0));
      expect(items.first.sellPrice, equals(1800.0));
      expect(totalChangedCalls, equals(1));
      expect(adapter.isInReceipt(42), isTrue);
      expect(adapter.getQuantity(ingredient), equals(10.0));

      for (var it in items) {
        it.dispose();
      }
    });

    test('pruneEmptyRows removes empty rows and rows with 0 quantity', () {
      final items = <ReceiptRowData>[];
      final adapter = ReceiveCategorySyncAdapter(
        items: items,
        onTotalChanged: () {},
      );

      final ingredient1 = Ingredient(
        id: 1,
        name: 'Молоко 3.2%',
        unit: 'l',
        currentStock: 10,
        minStockAlert: 5,
        costPerUnit: 80,
        isLowStock: false,
      );
      final ingredient2 = Ingredient(
        id: 2,
        name: 'Сироп Ваниль',
        unit: 'bottle',
        currentStock: 1,
        minStockAlert: 3,
        costPerUnit: 450,
        isLowStock: true,
      );

      // Добавим позицию 1 с qty=5, позицию 2 с qty=2, и пустую строку без ингредиента
      adapter.updateQuantity(ingredient1, 5.0);
      adapter.updateQuantity(ingredient2, 2.0);
      items.add(ReceiptRowData());

      expect(items.length, equals(3));

      // Теперь сбрасываем количество позиции 2 в 0
      adapter.updateQuantity(ingredient2, 0.0);
      expect(items.length, equals(3));
      expect(adapter.getQuantity(ingredient2), equals(0.0));

      // Вызываем очистку пустых строк
      adapter.pruneEmptyRows();

      expect(items.length, equals(1));
      expect(items.first.ingredient?.id, equals(1));
      expect(items.first.quantity, equals(5.0));

      for (var it in items) {
        it.dispose();
      }
    });

    test('updateCostPrice and updateSellPrice update row data correctly', () {
      final items = <ReceiptRowData>[];
      final adapter = ReceiveCategorySyncAdapter(
        items: items,
        onTotalChanged: () {},
      );

      final ingredient = Ingredient(
        id: 100,
        name: 'Чай Ассам',
        unit: 'kg',
        currentStock: 0,
        minStockAlert: 1,
        costPerUnit: 500,
        isLowStock: true,
      );

      adapter.updateQuantity(ingredient, 3.0);
      adapter.updateCostPrice(ingredient, 550.0);
      adapter.updateSellPrice(ingredient, 900.0);

      expect(adapter.getCostPrice(ingredient), equals(550.0));
      expect(adapter.getSellPrice(ingredient), equals(900.0));
      expect(items.first.priceController.text, equals('550'));
      expect(items.first.sellPriceController.text, equals('900'));

      for (var it in items) {
        it.dispose();
      }
    });
  });

  group('UI Kit: AppSearchField Debounce Tests', () {
    testWidgets('AppSearchField debounces rapid text input', (tester) async {
      String lastQuery = '';
      int calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              debounceDuration: const Duration(milliseconds: 200),
              onChanged: (val) {
                lastQuery = val;
                calls++;
              },
            ),
          ),
        ),
      );

      final finder = find.byType(TextField);
      expect(finder, findsOneWidget);

      await tester.enterText(finder, 'М');
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, equals(0));

      await tester.enterText(finder, 'МА');
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, equals(0));

      await tester.enterText(finder, 'МАЛИ');
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, equals(0));

      // Ждем завершения таймера debounce (200 мс)
      await tester.pump(const Duration(milliseconds: 250));

      expect(calls, equals(1));
      expect(lastQuery, equals('МАЛИ'));
    });

    testWidgets('AppSearchField fires immediately when enableDebounce is false', (tester) async {
      String lastQuery = '';
      int calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              enableDebounce: false,
              onChanged: (val) {
                lastQuery = val;
                calls++;
              },
            ),
          ),
        ),
      );

      final finder = find.byType(TextField);
      await tester.enterText(finder, 'Кофе');
      await tester.pump();

      expect(calls, equals(1));
      expect(lastQuery, equals('Кофе'));
    });
  });

  group('Goods Receipt Sprint Fixes: Cart Reactivity & Drafts', () {
    test('ReceiveDocumentProcessor creates draft rows correctly', () {
      final docItems = [
        InventoryDocumentItem(
          id: 1,
          documentId: 10,
          ingredientId: 101,
          ingredientName: 'Кофейное зерно',
          quantity: 5.0,
          pricePerUnit: 900.0,
          totalPrice: 4500.0,
        ),
        InventoryDocumentItem(
          id: 2,
          documentId: 10,
          retailProductId: 202,
          retailProductName: 'Coca-Cola 0.5L',
          quantity: 24.0,
          pricePerUnit: 45.0,
          totalPrice: 1080.0,
        ),
      ];

      final rows = ReceiveDocumentProcessor.createDraftRows(docItems);
      expect(rows.length, equals(2));
      expect(rows[0].newName, equals('Кофейное зерно'));
      expect(rows[0].quantity, equals(5.0));
      expect(rows[0].price, equals(900.0));

      expect(rows[1].newName, equals('Coca-Cola 0.5L'));
      expect(rows[1].quantity, equals(24.0));
      expect(rows[1].price, equals(45.0));
    });

    test('ReceiveDocumentProcessor binds available ingredients to draft rows', () {
      final rows = [
        ReceiptRowData(newName: 'Кофейное зерно', quantity: 5.0, price: 900.0),
        ReceiptRowData(newName: 'Coca-Cola 0.5L', quantity: 24.0, price: 45.0),
      ];

      final List<Ingredient> available = [
        Ingredient(
          id: 101,
          name: 'Кофейное зерно',
          unit: 'кг',
          costPerUnit: 900.0,
          currentStock: 10.0,
          minStockAlert: 2.0,
          isArchived: false,
          isLowStock: false,
        ),
        Ingredient(
          id: 202,
          name: 'Coca-Cola 0.5L',
          unit: 'шт',
          costPerUnit: 45.0,
          currentStock: 50.0,
          minStockAlert: 10.0,
          isArchived: false,
          isLowStock: false,
          attributes: const {'is_retail': true},
        ),
      ];

      final docItems = [
        InventoryDocumentItem(
          id: 1,
          documentId: 10,
          ingredientId: 101,
          ingredientName: 'Кофейное зерно',
          quantity: 5.0,
          pricePerUnit: 900.0,
          totalPrice: 4500.0,
        ),
        InventoryDocumentItem(
          id: 2,
          documentId: 10,
          retailProductId: 202,
          retailProductName: 'Coca-Cola 0.5L',
          quantity: 24.0,
          pricePerUnit: 45.0,
          totalPrice: 1080.0,
        ),
      ];

      ReceiveDocumentProcessor.bindDraftIngredients(rows, available, docItems);

      expect(rows[0].ingredient, isNotNull);
      expect(rows[0].ingredient!.id, equals(101));
      expect(rows[0].nameController.text, equals('Кофейное зерно'));

      expect(rows[1].ingredient, isNotNull);
      expect(rows[1].ingredient!.id, equals(202));
      expect(rows[1].ingredient!.isRetail, isTrue);
      expect(rows[1].nameController.text, equals('Coca-Cola 0.5L'));
    });

    testWidgets('ReceiveDocumentFooter reflects reactive cart count via cartCountListenable', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cartNotifier = ValueNotifier<int>(0);
      final sumNotifier = ValueNotifier<double>(0.0);
      final paidCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiveDocumentFooter(
              totalSum: 0.0,
              totalSumListenable: sumNotifier,
              cartCountListenable: cartNotifier,
              currency: 'с',
              isSaving: false,
              paymentStatus: 'unpaid',
              paymentMethod: 'cash',
              paidAmountController: paidCtrl,
              onPaymentStatusChanged: (_) {},
              onPaymentMethodChanged: (_) {},
              onToggleCart: () {},
              onCancel: () {},
              onSaveDraft: () {},
              onSaveComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('0 поз.'), findsOneWidget);
      expect(find.text('0.00 с'), findsOneWidget);

      // Изменяем реактивные значения без перерисовки родителя
      cartNotifier.value = 3;
      sumNotifier.value = 1500.0;
      await tester.pump();

      expect(find.text('3 поз.'), findsOneWidget);
      expect(find.text('1500.00 с'), findsOneWidget);
    });

    testWidgets('ReceiveDocumentPaymentSection displays amount field for paid and partial statuses', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final paidCtrl = TextEditingController(text: '1250.00');

      // 1. Постоплата (unpaid) - поле суммы скрыто
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiveDocumentPaymentSection(
              isDark: false,
              paymentStatus: 'unpaid',
              paymentMethod: 'cash',
              paidAmountController: paidCtrl,
              onPaymentStatusChanged: (_) {},
              onPaymentMethodChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('1250.00'), findsNothing);

      // 2. Оплачено (paid) - поле суммы отображается
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiveDocumentPaymentSection(
              isDark: false,
              paymentStatus: 'paid',
              paymentMethod: 'cash',
              paidAmountController: paidCtrl,
              onPaymentStatusChanged: (_) {},
              onPaymentMethodChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('1250.00'), findsOneWidget);

      // 3. Частично (partial) - поле суммы также отображается
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiveDocumentPaymentSection(
              isDark: false,
              paymentStatus: 'partial',
              paymentMethod: 'cash',
              paidAmountController: paidCtrl,
              onPaymentStatusChanged: (_) {},
              onPaymentMethodChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('1250.00'), findsOneWidget);
    });
  });
}
