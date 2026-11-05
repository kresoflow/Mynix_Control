// ==============================================================================
// ТЕСТ: Изоляция статусов загрузки склада и поставщиков
// ДОМЕН: test/supplier_status_isolation_test.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [СТАТУСЫ-BLOC] Защита от бесконечного шиммера при Hot Restart:
// 1. suppliersStatus переходит в DocumentStatus.success даже при 0 поставщиков.
// 2. status (документы) и suppliersStatus (поставщики) полностью изолированы.
// 3. Одновременный запуск LoadDocuments и LoadSuppliers завершается в success.
//
// ==============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_state.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';

InventoryRepository _createMockInventoryRepository({
  List<dynamic> suppliersData = const [],
  List<dynamic> documentsData = const [],
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/suppliers')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: suppliersData,
            ),
          );
        }
        if (options.path.contains('/documents')) {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: documentsData,
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

  group('DocumentBloc - Suppliers & Documents Status Isolation', () {
    test('LoadSuppliers с пустым списком поставщиков переходит в success', () async {
      final repo = _createMockInventoryRepository(suppliersData: []);
      final bloc = DocumentBloc(repo);

      expect(bloc.state.suppliersStatus, equals(DocumentStatus.initial));
      expect(bloc.state.status, equals(DocumentStatus.initial));

      bloc.add(const LoadSuppliers());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<DocumentState>((s) => s.suppliersStatus == DocumentStatus.loading),
          predicate<DocumentState>(
            (s) =>
                s.suppliersStatus == DocumentStatus.success &&
                s.suppliers.isEmpty &&
                s.status == DocumentStatus.initial, // status документов не затронут!
          ),
        ]),
      );

      await bloc.close();
    });

    test('LoadDocuments не перезатирает suppliersStatus', () async {
      final repo = _createMockInventoryRepository(documentsData: []);
      final bloc = DocumentBloc(repo);

      bloc.add(const LoadDocuments());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<DocumentState>((s) => s.status == DocumentStatus.loading),
          predicate<DocumentState>(
            (s) =>
                s.status == DocumentStatus.success &&
                s.documents.isEmpty &&
                s.suppliersStatus == DocumentStatus.initial, // suppliersStatus не затронут!
          ),
        ]),
      );

      await bloc.close();
    });

    test('Параллельный вызов LoadDocuments и LoadSuppliers переводит оба статуса в success', () async {
      final repo = _createMockInventoryRepository(
        documentsData: [],
        suppliersData: [],
      );
      final bloc = DocumentBloc(repo);

      bloc.add(const LoadDocuments());
      bloc.add(const LoadSuppliers());

      // Ждем завершения обоих асинхронных потоков событий
      await untilCalledOrTimeout(
        bloc.stream,
        condition: (s) =>
            s.status == DocumentStatus.success &&
            s.suppliersStatus == DocumentStatus.success,
      );

      expect(bloc.state.status, equals(DocumentStatus.success));
      expect(bloc.state.suppliersStatus, equals(DocumentStatus.success));
      expect(bloc.state.documents.isEmpty, isTrue);
      expect(bloc.state.suppliers.isEmpty, isTrue);

      await bloc.close();
    });
  });
}

Future<void> untilCalledOrTimeout(
  Stream<DocumentState> stream, {
  required bool Function(DocumentState) condition,
  Duration timeout = const Duration(seconds: 3),
}) async {
  await for (final state in stream.timeout(timeout)) {
    if (condition(state)) return;
  }
}
