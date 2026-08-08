import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsMetrics metrics;
  final AnalyticsXRay xray;

  const AnalyticsLoaded({required this.metrics, required this.xray});

  @override
  List<Object?> get props => [metrics, xray];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
