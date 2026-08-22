import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';

/// Global BLoC observer for exception capture, telemetry, and debugging.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // 🛠️ Local Debug: readable console formatting
    if (kDebugMode) {
      debugPrint('🚨 [BLoC Error] ${bloc.runtimeType}: $error');
    }

    // 🛡️ Production Release: forward to Sentry & server Telegram bridge
    if (kReleaseMode) {
      // 1. Sentry Crash Report
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('bloc', bloc.runtimeType.toString());
        },
      );

      // 2. Safe Telegram Bridge (non-blocking)
      _reportClientError(bloc, error, stackTrace);
    }

    super.onError(bloc, error, stackTrace);
  }

  void _reportClientError(BlocBase bloc, Object error, StackTrace stackTrace) async {
    try {
      await apiClient.dio.post(
        '/system/client-error',
        data: {
          'bloc': bloc.runtimeType.toString(),
          'error': error.toString(),
          'stack_trace': stackTrace.toString().split('\n').take(5).join('\n'),
        },
      );
    } catch (_) {
      // Silently ignore bridge delivery failures
    }
  }
}

