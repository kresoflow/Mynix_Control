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

  /// Fetch X-Report for current open shift
  Future<Map<String, dynamic>> getXReport() async {
    try {
      final response = await _dio.get('/shifts/x-report');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load X-Report: $e');
    }
  }

  /// Record cash expense/withdrawal
  Future<Map<String, dynamic>> recordExpense(double amount, String description) async {
    try {
      final response = await _dio.post(
        '/cash/expense',
        data: {'amount': amount, 'description': description},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to record cash expense: $e');
    }
  }

  /// Fetch shifts history
  Future<List<Map<String, dynamic>>> getShiftsHistory({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/shifts/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final list = response.data['history'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to load shifts history: $e');
    }
  }
}

