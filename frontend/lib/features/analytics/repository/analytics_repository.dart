import 'package:dio/dio.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';
import 'package:intl/intl.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(this._dio);

  Future<AnalyticsMetrics> getMetrics({
    required String period,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final query = {'period': period};
      if (start != null && end != null) {
        query['start'] = DateFormat('yyyy-MM-dd').format(start);
        query['end'] = DateFormat('yyyy-MM-dd').format(end);
      }
      final response = await _dio.get('/analytics/metrics', queryParameters: query);
      return AnalyticsMetrics.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load analytics metrics: ${e.toString()}');
    }
  }

  Future<AnalyticsXRay> getXRay({
    required String period,
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final query = {'period': period};
      if (start != null && end != null) {
        query['start'] = DateFormat('yyyy-MM-dd').format(start);
        query['end'] = DateFormat('yyyy-MM-dd').format(end);
      }
      final response = await _dio.get('/analytics/xray', queryParameters: query);
      return AnalyticsXRay.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load analytics x-ray: ${e.toString()}');
    }
  }
}
