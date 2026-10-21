// ==============================================================================
// МОДУЛЬ: Аналитика / События BLoC аналитического дашборда (AnalyticsEvent)
// ДОМЕН: lib/features/analytics/bloc/analytics_event.dart
// ==============================================================================

import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

// ── Запрос аналитических данных (метрики + X-Ray) ────────────────────────────
class LoadAnalytics extends AnalyticsEvent {
  final String period; // 'today', 'week', 'month', 'year', 'custom'
  final DateTime? startDate;
  final DateTime? endDate;
  final bool forceRefresh;

  const LoadAnalytics({
    required this.period,
    this.startDate,
    this.endDate,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [period, startDate, endDate, forceRefresh];
}

// ── Сброс кэша и состояния аналитики (при логауте или смене тенанта) ─────────
class ResetAnalytics extends AnalyticsEvent {}
