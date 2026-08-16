part of '../inventory_repository.dart';

extension DocumentsPart on InventoryRepository {
  Future<List<InventoryDocument>> getDocuments({String? type}) async {
    try {
      final response = await _dio.get('/documents/', queryParameters: {
        'type': ?type,
      });
      final data = response.data as List;
      return data.map((json) => InventoryDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load documents: ${e.toString()}');
    }
  }

  Future<InventoryDocument> getDocument(int id) async {
    try {
      final response = await _dio.get('/documents/$id');
      return InventoryDocument.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load document details: ${e.toString()}');
    }
  }

  Future<InventoryDocument> createDocument(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/documents/', data: data);
      return InventoryDocument.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to create document');
      }
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  Future<InventoryDocument> completeDocument(int id) async {
    try {
      final response = await _dio.post('/documents/$id/complete');
      return InventoryDocument.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to complete document');
      }
      throw Exception('Failed to complete document: ${e.toString()}');
    }
  }
}
