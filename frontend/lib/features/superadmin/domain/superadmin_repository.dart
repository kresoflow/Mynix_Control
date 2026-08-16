import 'package:dio/dio.dart';

class Tenant {
  final int id;
  final String name;
  final String schemaName;
  final String address;
  final bool isActive;
  final String createdAt;

  Tenant({
    required this.id,
    required this.name,
    required this.schemaName,
    required this.address,
    required this.isActive,
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
      schemaName: json['schema_name'],
      address: json['address'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
    );
  }
}

class SuperadminRepository {
  final Dio dio;

  SuperadminRepository({required this.dio});

  Future<List<Tenant>> getTenants(String systemToken) async {
    final response = await dio.get(
      '/system/tenants',
      options: Options(headers: {'x-system-token': systemToken}),
    );
    return (response.data as List).map((t) => Tenant.fromJson(t)).toList();
  }

  Future<int> createTenant({
    required String systemToken,
    required String name,
    required String schemaName,
    required String address,
    required String ownerUsername,
    required String ownerPassword,
    required String ownerFullName,
    String ownerPinCode = '1234',
    String? ownerPhone,
    String? ownerEmail,
    bool useKds = true,
    bool enableInventoryDeduction = true,
  }) async {
    final response = await dio.post(
      '/system/tenants',
      options: Options(headers: {'x-system-token': systemToken}),
      data: {
        'name': name,
        'schema_name': schemaName,
        'address': address,
        'owner_username': ownerUsername,
        'owner_password': ownerPassword,
        'owner_full_name': ownerFullName,
        'owner_pin_code': ownerPinCode,
        if (ownerPhone != null && ownerPhone.isNotEmpty) 'owner_phone': ownerPhone,
        if (ownerEmail != null && ownerEmail.isNotEmpty) 'owner_email': ownerEmail,
        'use_kds': useKds,
        'enable_inventory_deduction': enableInventoryDeduction,
      },
    );
    return response.data['tenant_id'];
  }

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

  Future<void> updateTableRow({
    required String systemToken,
    required String schemaName,
    required String tableName,
    required Map<String, dynamic> payload, // Must include PKs
  }) async {
    await dio.put(
      '/system/tenants/$schemaName/tables/$tableName',
      data: payload,
      options: Options(headers: {'x-system-token': systemToken}),
    );
  }

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
}
