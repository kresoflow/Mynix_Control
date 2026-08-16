part of '../inventory_repository.dart';

extension SuppliersPart on InventoryRepository {
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _dio.get('/suppliers/');
      final data = response.data as List;
      return data.map((json) => Supplier.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load suppliers: ${e.toString()}');
    }
  }

  Future<Supplier> createSupplier(String name, {String? contactInfo}) async {
    try {
      final response = await _dio.post(
        '/suppliers/',
        data: {
          'name': name,
          'contact_info': ?contactInfo,
        },
      );
      return Supplier.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create supplier: ${e.toString()}');
    }
  }

  Future<void> updateSupplier(int id, {String? name, String? contactInfo, bool? isActive}) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (contactInfo != null) data['contact_info'] = contactInfo;
      if (isActive != null) data['is_active'] = isActive;
      await _dio.put('/suppliers/$id', data: data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to update supplier');
      }
      throw Exception('Failed to update supplier: ${e.toString()}');
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _dio.delete('/suppliers/$id');
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to delete supplier');
      }
      throw Exception('Failed to delete supplier: ${e.toString()}');
    }
  }
}
