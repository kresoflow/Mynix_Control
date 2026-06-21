import 'package:dio/dio.dart';
import 'package:retail_os_frontend/features/analytics/models/dashboard_data.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(this._dio);

  Future<DashboardData> getDashboardToday() async {
    try {
      final response = await _dio.get('/analytics/dashboard/today');
      return DashboardData.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load dashboard data: ${e.toString()}');
    }
  }
}
