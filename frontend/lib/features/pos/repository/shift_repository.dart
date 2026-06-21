import 'package:dio/dio.dart';

class ShiftRepository {
  final Dio _dio;

  ShiftRepository(this._dio);

  /// Fetch the current open shift
  /// Returns a Map with shift details if open, or null if no open shift
  Future<Map<String, dynamic>?> getCurrentShift() async {
    try {
      final response = await _dio.get('/shifts/current');
      if (response.data['shift'] != null) {
        return response.data['shift'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to check current shift: $e');
    }
  }

  /// Open a new shift
  Future<Map<String, dynamic>> openShift(double openingCash) async {
    try {
      final response = await _dio.post(
        '/shifts/open',
        data: {'opening_cash': openingCash},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to open shift: $e');
    }
  }

  /// Close the current shift
  Future<Map<String, dynamic>> closeShift(double closingCashActual) async {
    try {
      final response = await _dio.post(
        '/shifts/close',
        data: {'closing_cash_actual': closingCashActual},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to close shift: $e');
    }
  }
}
