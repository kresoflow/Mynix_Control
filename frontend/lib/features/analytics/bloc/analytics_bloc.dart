// ==============================================================================
// МОДУЛЬ: Аналитика / Управление состоянием дашборда (AnalyticsBloc)
// ДОМЕН: lib/features/analytics/bloc/analytics_bloc.dart
// ==============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/analytics/models/analytics_models.dart';
import 'package:kreso_frontend/features/analytics/repository/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

// ── BLoC аналитики с поддержкой Stale-While-Revalidate (SWR) ─────────────────
/// [ИНВАРИАНТ] Никогда не разрушает текущую верстку при повторном запросе данных.
/// Если данные уже есть в памяти, они отдаются мгновенно, а обновление выполняется
/// в фоновом режиме через флаг isRefreshing: true.
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  // Кэш аналитики в памяти сессии: ключ периода -> (metrics, xray)
  final Map<String, ({AnalyticsMetrics metrics, AnalyticsXRay xray})> _cache = {};

  AnalyticsBloc(this.repository) : super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
    on<ResetAnalytics>(_onResetAnalytics);
  }

  String _cacheKey(String period, DateTime? start, DateTime? end) {
    if (period == 'custom') {
      return 'custom:${start?.toIso8601String() ?? ""}:${end?.toIso8601String() ?? ""}';
    }
    return period;
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    final key = _cacheKey(event.period, event.startDate, event.endDate);
    final cached = _cache[key];

    if (cached != null) {
      // 1. Быстрый путь: данные есть в кэше — отдаём мгновенно, включаем тихий фон
      emit(
        AnalyticsLoaded(
          metrics: cached.metrics,
          xray: cached.xray,
          period: event.period,
          startDate: event.startDate,
          endDate: event.endDate,
          isRefreshing: true,
        ),
      );
    } else if (state is AnalyticsLoaded) {
      // 2. Смена периода без кэша: сохраняем верстку, включаем индикатор обновления
      emit(
        (state as AnalyticsLoaded).copyWith(
          period: event.period,
          startDate: event.startDate,
          endDate: event.endDate,
          isRefreshing: true,
        ),
      );
    } else {
      // 3. Первичный холодный старт (данных ещё нет вообще)
      emit(AnalyticsLoading(period: event.period));
    }

    try {
      final metricsData = await repository.getMetrics(
        period: event.period,
        start: event.startDate,
        end: event.endDate,
      );
      final xrayData = await repository.getXRay(
        period: event.period,
        start: event.startDate,
        end: event.endDate,
      );

      _cache[key] = (metrics: metricsData, xray: xrayData);

      emit(
        AnalyticsLoaded(
          metrics: metricsData,
          xray: xrayData,
          period: event.period,
          startDate: event.startDate,
          endDate: event.endDate,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      // Если запрос завершился ошибкой, но есть старые данные — не ломаем верстку!
      final prevMetrics = cached?.metrics ??
          (state is AnalyticsLoaded ? (state as AnalyticsLoaded).metrics : null);
      final prevXray = cached?.xray ??
          (state is AnalyticsLoaded ? (state as AnalyticsLoaded).xray : null);

      if (prevMetrics != null && prevXray != null) {
        emit(
          AnalyticsLoaded(
            metrics: prevMetrics,
            xray: prevXray,
            period: event.period,
            startDate: event.startDate,
            endDate: event.endDate,
            isRefreshing: false,
          ),
        );
      } else {
        emit(AnalyticsError(e.toString(), period: event.period));
      }
    }
  }

  void _onResetAnalytics(ResetAnalytics event, Emitter<AnalyticsState> emit) {
    _cache.clear();
    emit(AnalyticsInitial());
  }
}
