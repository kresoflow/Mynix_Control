import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1'; // Local Dev Backend

  final Dio dio;

  ApiClient() : dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
  )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Retrieve token from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          if (kDebugMode) {
            print('--> [${options.method}] ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('<-- [${response.statusCode}] ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            print('<!> [${e.response?.statusCode}] ${e.requestOptions.uri} - ${e.message}');
          }
          
          if (e.response?.statusCode == 401) {
            // Unauthorized - We could clear token and redirect to Login here
            // This logic is usually coordinated via the AuthBloc listening to a stream
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
          }
          
          return handler.next(e);
        },
      ),
    );
  }
}

// Singleton provider for DI
final apiClient = ApiClient();
