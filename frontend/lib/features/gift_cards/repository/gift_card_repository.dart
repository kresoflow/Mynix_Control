// ==============================================================================
// МОДУЛЬ: Подарочные карты (Gift Cards)
// ДОМЕН: lib/features/gift_cards/repository/gift_card_repository.dart
// ==============================================================================
import 'package:dio/dio.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/features/gift_cards/models/gift_card.dart';

/// Репозиторий взаимодействия с API подарочных карт.
/// 
/// [ИНВАРИАНТ] Все сетевые вызовы изолированы в слое Repository.
class GiftCardRepository {
  final Dio _dio;

  GiftCardRepository({Dio? dio}) : _dio = dio ?? apiClient.dio;

  // ─── 1. Эмиссия и выпуск карты ──────────────────────────────────────────────

  /// Выпускает новую подарочную карту с заданным номиналом.
  /// 
  /// [ФИНАНСЫ] initialBalance должен быть больше нуля.
  Future<GiftCard> issueGiftCard({
    String? code,
    required double initialBalance,
    DateTime? expiryDate,
    int? customerId,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'initial_balance': initialBalance,
      if (code != null && code.trim().isNotEmpty) 'code': code.trim().toUpperCase(),
      if (expiryDate != null) 'expiry_date': expiryDate.toIso8601String().split('T')[0],
      if (customerId != null) 'customer_id': customerId,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await _dio.post('/gift-cards', data: payload);
    return GiftCard.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── 2. Поиск и получение списка карт ───────────────────────────────────────

  /// Получает пагинированный список подарочных карт с фильтрацией.
  Future<({List<GiftCard> items, int total})> getGiftCards({
    String? search,
    bool? isActive,
    int? customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (isActive != null) 'is_active': isActive,
      if (customerId != null) 'customer_id': customerId,
    };

    final response = await _dio.get('/gift-cards', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => GiftCard.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = data['total'] as int? ?? items.length;

    return (items: items, total: total);
  }

  /// Ищет карту по уникальному коду (для быстрой проверки на кассе).
  Future<GiftCard?> lookupGiftCard(String code) async {
    try {
      final response = await _dio.get(
        '/gift-cards/lookup',
        queryParameters: {'code': code.trim().toUpperCase()},
      );
      return GiftCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Загружает детальную информацию о карте по ее ID.
  Future<GiftCard> getGiftCardById(int cardId) async {
    final response = await _dio.get('/gift-cards/$cardId');
    return GiftCard.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── 3. Списание, пополнение и изменение статуса ────────────────────────────

  /// Списывает указанную сумму с карты при оплате заказа.
  /// 
  /// [ИНВАРИАНТ] Сумма не может превышать текущий баланс карты.
  Future<GiftCard> redeemGiftCard({
    required int cardId,
    required double amount,
    int? orderId,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount,
      if (orderId != null) 'order_id': orderId,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await _dio.post('/gift-cards/$cardId/redeem', data: payload);
    return GiftCard.fromJson(response.data as Map<String, dynamic>);
  }

  /// Пополняет баланс подарочной карты.
  Future<GiftCard> topUpGiftCard({
    required int cardId,
    required double amount,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await _dio.post('/gift-cards/$cardId/topup', data: payload);
    return GiftCard.fromJson(response.data as Map<String, dynamic>);
  }

  /// Обновляет активность или статус карты.
  Future<GiftCard> updateGiftCardStatus({
    required int cardId,
    bool? isActive,
    String? status,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      if (isActive != null) 'is_active': isActive,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    };

    final response = await _dio.patch('/gift-cards/$cardId/status', data: payload);
    return GiftCard.fromJson(response.data as Map<String, dynamic>);
  }
}
