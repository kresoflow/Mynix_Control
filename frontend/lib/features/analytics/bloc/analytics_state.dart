// ==============================================================================
// МОДУЛЬ: Аналитика / Состояния BLoC аналитического дашборда (AnalyticsState)
// ДОМЕН: lib/features/analytics/bloc/analytics_state.dart
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:kreso_frontend/features/analytics/models/analytics_models.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

// ── Начальное состояние до первой инициализации ─────────────────────────────
class AnalyticsInitial extends AnalyticsState {}

// ── Состояние первичной холодной загрузки (без кэша) ────────────────────────
class AnalyticsLoading extends AnalyticsState {
  final String period;

  const AnalyticsLoading({this.period = 'today'});

  @override
  List<Object?> get props => [period];
}

// ── Состояние успешной загрузки (поддерживает тихий фон SWR) ─────────────────
class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsMetrics metrics;
  final AnalyticsXRay xray;
  final String period;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRefreshing;

  const AnalyticsLoaded({
    required this.metrics,
    required this.xray,
    this.period = 'today',
    this.startDate,
    this.endDate,
    this.isRefreshing = false,
  });

  AnalyticsLoaded copyWith({
    AnalyticsMetrics? metrics,
    AnalyticsXRay? xray,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isRefreshing,
  }) {
    return AnalyticsLoaded(
      metrics: metrics ?? this.metrics,
      xray: xray ?? this.xray,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [metrics, xray, period, startDate, endDate, isRefreshing];
}

// ── Состояние ошибки (с сохранением старых данных при наличии) ──────────────
class AnalyticsError extends AnalyticsState {
  final String message;
  final AnalyticsMetrics? previousMetrics;
  final AnalyticsXRay? previousXray;
  final String period;

  const AnalyticsError(
    this.message, {
    this.previousMetrics,
    this.previousXray,
    this.period = 'today',
  });

  @override
  List<Object?> get props => [message, previousMetrics, previousXray, period];
}
