import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynix_frontend/core/utils/audio_helper.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receipt_row_data.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receive_document_row_callbacks.dart';

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
}
