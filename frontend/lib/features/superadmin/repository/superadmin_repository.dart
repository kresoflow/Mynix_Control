// ============================================================================
// Kreso Flow | Superadmin Domain | Repository Implementation
// ============================================================================

import 'package:dio/dio.dart';
import '../models/tenant.dart';

// ─── 1. Superadmin Repository ────────────────────────────────────────────────

/// Репозиторий системного управления тенантами и системными таблицами Kreso Flow.
/// Использует заголовок x-system-token для авторизации на системном бэкенде.
class SuperadminRepository {
  final Dio dio;

  SuperadminRepository({required this.dio});

  /// Получение полного реестра тенантов с метаданными и владельцами.
  Future<List<Tenant>> getTenants(String systemToken) async {
    final response = await dio.get(
      '/system/tenants',
      options: Options(headers: {'x-system-token': systemToken}),
    );
    return (response.data as List).map((t) => Tenant.fromJson(t)).toList();
  }

  /// Регистрация нового тенанта с выделением PostgreSQL схемы и аккаунта владельца.
  Future<int> createTenant({
    required String systemToken,
    required String name,
    required String schemaName,
    required String address,
    String currency = 'сом',
    required String ownerUsername,
    required String ownerPassword,
    required String ownerFullName,
    String ownerPinCode = '1234',
    String? ownerPhone,
    String? ownerEmail,
    bool useKds = true,
    bool useOrders = true,
    bool enableInventoryDeduction = true,
  }) async {
    final response = await dio.post(
      '/system/tenants',
      options: Options(headers: {'x-system-token': systemToken}),
      data: {
        'name': name,
        'schema_name': schemaName,
        'address': address,
        'currency': currency,
        'owner_username': ownerUsername,
        'owner_password': ownerPassword,
        'owner_full_name': ownerFullName,
        'owner_pin_code': ownerPinCode,
        if (ownerPhone != null && ownerPhone.isNotEmpty) 'owner_phone': ownerPhone,
        if (ownerEmail != null && ownerEmail.isNotEmpty) 'owner_email': ownerEmail,
        'use_kds': useKds,
        'use_orders': useOrders,
        'enable_inventory_deduction': enableInventoryDeduction,
      },
    );
    return response.data['tenant_id'];
  }

  /// Получение списка всех таблиц в схеме тенанта.
  Future<List<String>> getSchemaTables({
    required String systemToken,
    required String schemaName,
  }) async {
    final response = await dio.get(
      '/system/tenants/$schemaName/tables',
      options: Options(headers: {'x-system-token': systemToken}),
    );
    return List<String>.from(response.data['tables']);
  }

  /// Получение данных таблицы с пагинацией и метаданными колонок.
  Future<Map<String, dynamic>> getTableData({
    required String systemToken,
    required String schemaName,
    required String tableName,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await dio.get(
      '/system/tenants/$schemaName/tables/$tableName',
      queryParameters: {'limit': limit, 'offset': offset},
      options: Options(headers: {'x-system-token': systemToken}),
    );
    return response.data;
  }

  /// Создание новой записи в таблице схемы.
  Future<Map<String, dynamic>> createTableRow({
    required String systemToken,
    required String schemaName,
    required String tableName,
    required Map<String, dynamic> payload,
  }) async {
    final response = await dio.post(
      '/system/tenants/$schemaName/tables/$tableName',
      data: payload,
      options: Options(headers: {'x-system-token': systemToken}),
    );
    return response.data['data'];
  }

  /// Обновление существующей строки в таблице схемы (требуются первичные ключи).
  Future<void> updateTableRow({
    required String systemToken,
    required String schemaName,
    required String tableName,
    required Map<String, dynamic> payload,
  }) async {
    await dio.put(
      '/system/tenants/$schemaName/tables/$tableName',
      data: payload,
      options: Options(headers: {'x-system-token': systemToken}),
    );
  }

  /// Удаление строки таблицы по первичному ключу.
  Future<void> deleteTableRow({
    required String systemToken,
    required String schemaName,
    required String tableName,
    required Map<String, dynamic> pkPayload,
  }) async {
    await dio.delete(
      '/system/tenants/$schemaName/tables/$tableName',
      data: pkPayload,
      options: Options(headers: {'x-system-token': systemToken}),
    );
  }

  /// Переключение активности тенанта (заморозка / разморозка доступа).
  Future<bool> toggleTenantStatus({
    required String systemToken,
    required int tenantId,
    required bool isActive,
  }) async {
    final response = await dio.patch(
      '/system/tenants/$tenantId/status',
      data: {'is_active': isActive},
      options: Options(headers: {'x-system-token': systemToken}),
    );
    return response.data['is_active'] as bool;
  }

  /// Комплексное обновление настроек организации и реквизитов владельца.
  Future<void> updateTenant({
    required String systemToken,
    required int tenantId,
    String? name,
    String? address,
    String? currency,
    bool? isActive,
    bool? useKds,
    bool? useOrders,
    bool? enableInventoryDeduction,
    String? ownerFullName,
    String? ownerPhone,
    String? ownerEmail,
    String? ownerPassword,
    String? ownerPinCode,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (address != null) payload['address'] = address;
    if (currency != null) payload['currency'] = currency;
    if (isActive != null) payload['is_active'] = isActive;
    if (useKds != null) payload['use_kds'] = useKds;
    if (useOrders != null) payload['use_orders'] = useOrders;
    if (enableInventoryDeduction != null) {
      payload['enable_inventory_deduction'] = enableInventoryDeduction;
    }
    if (ownerFullName != null) payload['owner_full_name'] = ownerFullName;
    if (ownerPhone != null) payload['owner_phone'] = ownerPhone;
    if (ownerEmail != null) payload['owner_email'] = ownerEmail;
    if (ownerPassword != null && ownerPassword.isNotEmpty) {
      payload['owner_password'] = ownerPassword;
    }
    if (ownerPinCode != null) payload['owner_pin_code'] = ownerPinCode;

    await dio.put(
      '/system/tenants/$tenantId',
      data: payload,
      options: Options(headers: {'x-system-token': systemToken}),
    );
  }

  /// Полное удаление организации и ее схемы из базы данных.
  Future<void> deleteTenant({
    required String systemToken,
    required int tenantId,
  }) async {
    await dio.delete(
      '/system/tenants/$tenantId',
      options: Options(headers: {'x-system-token': systemToken}),
    );
  }
}
