import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';

class ApiClient {
  static String get _baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && (host == 'localhost' || host == '127.0.0.1')) {
        return 'http://$host:8000/api/v1';
      }
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  final Dio dio;
  VoidCallback? onUnauthorized;
  bool _isHandling401 = false;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
    dio.addSentry();
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
          // 1. Automatic retry for transient disconnects on idempotent GET requests
          final isGet = e.requestOptions.method.toUpperCase() == 'GET';
          final retryCount = (e.requestOptions.extra['_retry_count'] as int?) ?? 0;
          final isNetworkIssue = e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              (e.message != null && e.message!.contains('XMLHttpRequest'));

          if (isGet && isNetworkIssue && retryCount < 2) {
            e.requestOptions.extra['_retry_count'] = retryCount + 1;
            await Future.delayed(Duration(milliseconds: 700 * (retryCount + 1)));
            try {
              final retryResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              // Retry failed, proceed to error mapping
            }
          }

          // 2. Map low-level browser / network errors to clear Russian messages
          final humanMessage = _mapErrorMessage(e);
          final formattedException = e.copyWith(message: humanMessage);

          if (kDebugMode) {
            final code = e.response?.statusCode?.toString() ?? 'NET_FAIL';
            print('<!> [$code] ${e.requestOptions.uri} - $humanMessage');
          }
          
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
            if (!_isHandling401) {
              _isHandling401 = true;
              onUnauthorized?.call();
              Future.delayed(const Duration(seconds: 2), () {
                _isHandling401 = false;
              });
            }
          }
          
          return handler.next(formattedException);
        },
      ),
    );
  }

  static String _mapErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Таймаут соединения: сервер не ответил вовремя. Проверьте сеть.';
      case DioExceptionType.connectionError:
        return 'Сервер недоступен (${e.requestOptions.baseUrl}). Проверьте запуск службы бэкенда.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        if (code == 401) {
          return 'Сессия истекла. Пожалуйста, выполните вход заново.';
        }
        if (data is Map && data['detail'] != null) {
          final detail = data['detail'].toString();
          if (detail == 'Not authenticated') {
            return 'Сессия истекла. Пожалуйста, выполните вход заново.';
          }
          return detail;
        }
        if (code == 403) return 'Отказано в доступе (недостаточно прав PBAC).';
        if (code == 404) return 'Запрошенные данные не найдены на сервере.';
        if (code != null && code >= 500) return 'Внутренняя ошибка сервера ($code).';
        return 'Ошибка запроса ($code).';
      case DioExceptionType.cancel:
        return 'Запрос был отменён.';
      default:
        if (e.message != null && e.message!.contains('XMLHttpRequest')) {
          return 'Сетевой сбой в браузере: нет подключения к серверу ${e.requestOptions.baseUrl}.';
        }
        return e.message ?? 'Сетевая ошибка при обращении к серверу.';
    }
  }
}

// Singleton provider for DI
final apiClient = ApiClient();
