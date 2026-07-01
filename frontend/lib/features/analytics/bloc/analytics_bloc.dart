import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/analytics/repository/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsBloc(this.repository) : super(AnalyticsLoading()) {
    on<LoadDashboardToday>(_onLoadDashboardToday);
  }

  Future<void> _onLoadDashboardToday(
    LoadDashboardToday event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await repository.getDashboardToday();
      emit(AnalyticsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}
