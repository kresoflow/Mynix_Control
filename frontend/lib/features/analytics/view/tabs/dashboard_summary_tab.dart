import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_event.dart';
import 'package:mynix_frontend/features/analytics/bloc/analytics_state.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/revenue_chart_card.dart';
import '../widgets/category_pie_chart_card.dart';
import '../widgets/xray_table_card.dart';

class DashboardSummaryTab extends StatelessWidget {
  final String selectedPeriod;
  final DateTime? startDate;
  final DateTime? endDate;

  const DashboardSummaryTab({
    super.key,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AnalyticsError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }

        if (state is AnalyticsLoaded) {
          final metrics = state.metrics;
          final xray = state.xray;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AnalyticsBloc>().add(
                    LoadAnalytics(
                      period: selectedPeriod,
                      startDate: startDate,
                      endDate: endDate,
                    ),
                  );
            },
            color: AppColors.brandPrimary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardKpiGrid(metrics: metrics),
                  const SizedBox(height: 24),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: RevenueChartCard(timeSeries: metrics.timeSeries),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: CategoryPieChartCard(categories: xray.categories),
                        ),
                      ],
                    )
                  else ...[
                    RevenueChartCard(timeSeries: metrics.timeSeries),
                    const SizedBox(height: 24),
                    CategoryPieChartCard(categories: xray.categories),
                  ],
                  const SizedBox(height: 24),
                  XRayTableCard(items: xray.items),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
