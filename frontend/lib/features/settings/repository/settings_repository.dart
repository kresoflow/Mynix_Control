import 'package:dio/dio.dart';

class SettingsRepository {
  final Dio _dio;

  SettingsRepository(this._dio);

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/settings/');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load settings: $e');
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      await _dio.put('/settings/', data: data);
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }
}
