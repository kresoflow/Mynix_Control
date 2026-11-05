// ==============================================================================
// ТЕСТ: OrdersBloc Real-time WebSocket Synchronisation
// ДОМЕН: test/orders_bloc_ws_test.dart
// ==============================================================================

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/network/websocket_service.dart';
import 'package:kreso_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:kreso_frontend/features/orders/models/pos_order.dart';
import 'package:kreso_frontend/features/orders/repository/orders_repository.dart';

// ── Фейковый WebSocket сервис для управляемой эмуляции сокет-событий ──────────
class FakeWebSocketService extends WebSocketService {
  final _testController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => _testController.stream;

  void emit(Map<String, dynamic> data) => _testController.add(data);

  @override
  void dispose() {
    _testController.close();
    super.dispose();
  }
}

// ── Фейковый репозиторий заказов ─────────────────────────────────────────────
class FakeOrdersRepository extends OrdersRepository {
  FakeOrdersRepository() : super(dio: Dio());

  int fetchCount = 0;
  String? lastStartDate;
  String? lastEndDate;
  List<PosOrder> ordersToReturn = [];

  @override
  Future<List<PosOrder>> fetchOrders({String? startDate, String? endDate}) async {
    fetchCount++;
    lastStartDate = startDate;
    lastEndDate = endDate;
    return ordersToReturn;
  }
}

void main() {
  late FakeWebSocketService fakeWs;
  late FakeOrdersRepository fakeRepo;
  late OrdersBloc ordersBloc;

  setUp(() {
    fakeWs = FakeWebSocketService();
    fakeRepo = FakeOrdersRepository();
    ordersBloc = OrdersBloc(repository: fakeRepo, wsService: fakeWs);
  });

  tearDown(() async {
    await ordersBloc.close();
    fakeWs.dispose();
  });

  test('Начальное состояние OrdersBloc — OrdersInitial', () {
    expect(ordersBloc.state, isA<OrdersInitial>());
  });

  test('LoadOrders загружает чеки и сохраняет переданный диапазон дат', () async {
    const start = '2026-10-28T00:00:00.000Z';
    const end = '2026-10-28T23:59:59.000Z';

    ordersBloc.add(const LoadOrders(startDate: start, endDate: end));
    await pumpEventQueue();

    expect(ordersBloc.state, isA<OrdersLoaded>());
    expect(fakeRepo.fetchCount, 1);
    expect(fakeRepo.lastStartDate, start);
    expect(fakeRepo.lastEndDate, end);
  });

  test('Событие order_created из WebSocket перезагружает список с сохранением дат', () async {
    const start = '2026-10-28T00:00:00.000Z';
    const end = '2026-10-28T23:59:59.000Z';

    ordersBloc.add(const LoadOrders(startDate: start, endDate: end));
    await pumpEventQueue();
    expect(fakeRepo.fetchCount, 1);

    // Эмулируем приход события order_created с кассы
    fakeWs.emit({'event': 'order_created', 'order_id': 42});

    // До истечения дебаунса (350мс) повторного запроса еще нет
    await Future.delayed(const Duration(milliseconds: 100));
    expect(fakeRepo.fetchCount, 1);

    // Ждем завершения дебаунса
    await Future.delayed(const Duration(milliseconds: 300));
    await pumpEventQueue();

    expect(fakeRepo.fetchCount, 2);
    expect(fakeRepo.lastStartDate, start);
    expect(fakeRepo.lastEndDate, end);
  });

  test('Дебаунс склеивает частые сокет-события в один запрос', () async {
    ordersBloc.add(const LoadOrders(startDate: 'd1', endDate: 'd2'));
    await pumpEventQueue();
    expect(fakeRepo.fetchCount, 1);

    // Спам из трех событий подряд
    fakeWs.emit({'event': 'order_created', 'order_id': 1});
    await Future.delayed(const Duration(milliseconds: 50));
    fakeWs.emit({'event': 'order_created', 'order_id': 2});
    await Future.delayed(const Duration(milliseconds: 50));
    fakeWs.emit({'event': 'order_status_updated', 'order_id': 3});

    // Ждем истечения таймера
    await Future.delayed(const Duration(milliseconds: 400));
    await pumpEventQueue();

    // Должен выполниться ровно 1 повторный fetch (всего 2: начальный + 1 дебаунснутый)
    expect(fakeRepo.fetchCount, 2);
  });

  test('Посторонние события сокета игнорируются', () async {
    ordersBloc.add(const LoadOrders());
    await pumpEventQueue();
    expect(fakeRepo.fetchCount, 1);

    fakeWs.emit({'event': 'unrelated_event', 'foo': 'bar'});
    await Future.delayed(const Duration(milliseconds: 400));
    await pumpEventQueue();

    expect(fakeRepo.fetchCount, 1);
  });
}
