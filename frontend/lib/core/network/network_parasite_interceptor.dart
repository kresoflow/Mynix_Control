// ==============================================================================
// МОДУЛЬ: Ядро сети / Детектор паразитных и дублирующих HTTP-запросов
// ДОМЕН: lib/core/network/network_parasite_interceptor.dart
// ==============================================================================
//
// [ИНВАРИАНТ] Сетевая ловушка реального времени (работает только в kDebugMode):
// 1. Детектирует дублирующие GET-запросы к одному URL в окне 3.0 сек.
// 2. Детектирует спам мутаций (POST/PUT/PATCH) чаще 400 мс (отсутствие debounce).
// 3. Выводит яркие предупреждения с точным временем между вызовами.
//
// ==============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Интерцептор Dio для обнаружения и логирования паразитных сетевых запросов.
class NetworkParasiteInterceptor extends Interceptor {
  /// История последних запросов: ключ -> DateTime
  static final Map<String, DateTime> _lastRequestTimes = {};

  /// Окно подозрительного дублирования GET-запросов (3.0 сек)
  static const Duration _duplicateGetThreshold = Duration(seconds: 3);

  /// Окно подозрительного спама мутаций без debounce (400 мс)
  static const Duration _rapidMutationThreshold = Duration(milliseconds: 400);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _checkParasiteRequest(options);
    }
    handler.next(options);
  }

  void _checkParasiteRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    final path = options.uri.path;
    final key = '$method:$path';
    final now = DateTime.now();

    final lastTime = _lastRequestTimes[key];
    _lastRequestTimes[key] = now;

    if (lastTime == null) return;

    final diff = now.difference(lastTime);

    if (method == 'GET' && diff < _duplicateGetThreshold) {
      debugPrint(
        '⚠️ \x1B[33m[PARASITE DETECTED: DUPLICATE GET]\x1B[0m '
        'GET $path вызван повторно спустя ${diff.inMilliseconds} мс! '
        'Проверьте initState/didUpdateWidget или отсутствие проверки кэша.',
      );
    } else if ((method == 'POST' || method == 'PUT' || method == 'PATCH') &&
        diff < _rapidMutationThreshold) {
      debugPrint(
        '🚨 \x1B[31m[PARASITE DETECTED: RAPID MUTATION]\x1B[0m '
        '$method $path вызван повторно спустя ${diff.inMilliseconds} мс! '
        'В UI или BLoC отсутствует debounce/отмена предыдущего запроса.',
      );
    }
  }

  /// Очистить историю запросов (например, при смене пользователя или в тестах)
  static void clearHistory() {
    _lastRequestTimes.clear();
  }
}
