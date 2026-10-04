// ==============================================================================
// СЕРВИС: Клиентский репортер ошибок и логов в бэкенд (Client Error Reporter)
// ДОМЕН: core/network/client_error_reporter.dart
// ==============================================================================

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:kreso_frontend/core/network/api_client.dart';

/// ── 1. Сервис захвата и пересылки ошибок UI в бэкенд ────────────────────────

class ClientErrorReporter {
  ClientErrorReporter._();

  static final Map<String, DateTime> _recentErrors = {};
  static const Duration _throttleWindow = Duration(seconds: 5);
  static bool _isInitialized = false;

  /// Инициализирует глобальные перехватчики ошибок в приложении.
  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Перехват ошибок вёрстки и Flutter-виджетов (RenderFlex overflow и др.)
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (originalOnError != null) {
        originalOnError(details);
      } else {
        FlutterError.presentError(details);
      }
      reportFlutterError(details);
    };

    // 2. Перехват асинхронных исключений в корневом PlatformDispatcher
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      reportAsyncError(error, stack);
      return false; // Позволяет Flutter продолжить стандартную обработку
    };
  }

  /// ── 2. Отправка ошибок рендеринга и оверфлоу ─────────────────────────────

  static void reportFlutterError(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    final isOverflow = message.contains('RenderFlex overflowed');
    final category = isOverflow ? 'LAYOUT_OVERFLOW' : 'FLUTTER_ERROR';

    // Формируем человекочитаемое имя компонента
    String component = details.context?.toDescription() ?? 'FlutterWidget';
    if (details.library != null && details.library!.isNotEmpty) {
      component += ' (${details.library})';
    }

    _sendPayload(
      category: category,
      component: component,
      errorMessage: message,
      stackTrace: details.stack?.toString(),
    );
  }

  /// ── 3. Отправка асинхронных ошибок ──────────────────────────────────────

  static void reportAsyncError(Object error, StackTrace stack) {
    _sendPayload(
      category: 'ASYNC_ERROR',
      component: 'PlatformDispatcher',
      errorMessage: error.toString(),
      stackTrace: stack.toString(),
    );
  }

  /// ── 4. Отправка ошибок BLoC ──────────────────────────────────────────────

  static void reportBlocError({
    required String blocName,
    required Object error,
    StackTrace? stackTrace,
  }) {
    _sendPayload(
      category: 'BLOC_ERROR',
      component: blocName,
      errorMessage: error.toString(),
      stackTrace: stackTrace?.toString(),
    );
  }

  /// ── 5. Внутренняя отправка с защитой от циклов и спама ───────────────────

  static void _sendPayload({
    required String category,
    required String component,
    required String errorMessage,
    String? stackTrace,
  }) async {
    try {
      // Анти-спам фильтр: предотвращаем 60 запросов/сек при перерисовке оверфлоу
      final errorSignature = '${category}_${component}_${errorMessage.split('\n').first}';
      final now = DateTime.now();
      final lastReported = _recentErrors[errorSignature];

      if (lastReported != null && now.difference(lastReported) < _throttleWindow) {
        return;
      }
      _recentErrors[errorSignature] = now;

      // Ограничиваем размер кэша
      if (_recentErrors.length > 100) {
        _recentErrors.remove(_recentErrors.keys.first);
      }

      // Вырезаем первые 6 строк стека для компактности
      final compactStack = stackTrace != null
          ? stackTrace.split('\n').take(6).join('\n')
          : null;

      final data = {
        'category': category,
        'component': component,
        'error': errorMessage.split('\n').first,
        'stack_trace': compactStack,
        'url': kIsWeb ? Uri.base.path : null,
      };

      // Не блокируем UI и не вызываем повторный цикл при ошибке сети
      await apiClient.dio.post(
        '/system/client-logs',
        data: data,
      );
    } catch (_) {
      // Игнорируем ошибки доставки (сервер может перезапускаться)
    }
  }
}
