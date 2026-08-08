import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/analytics/repository/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsBloc(this.repository) : super(AnalyticsLoading()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
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
      
      emit(AnalyticsLoaded(metrics: metricsData, xray: xrayData));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}
