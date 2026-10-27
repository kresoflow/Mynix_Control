// ==============================================================================
// МОДУЛЬ: Аналитика / Вкладка сводки дашборда (DashboardSummaryTab)
// ДОМЕН: lib/features/analytics/view/tabs/dashboard_summary_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_bloc.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_event.dart';
import 'package:kreso_frontend/features/analytics/bloc/analytics_state.dart';
import '../widgets/analytics_dashboard_skeleton.dart';
import '../widgets/dashboard_kpi_grid.dart';
import '../widgets/revenue_chart_card.dart';
import '../widgets/category_pie_chart_card.dart';
import '../widgets/xray_table_card.dart';

// ── Вкладка сводки показателей дашборда ──────────────────────────────────────
class DashboardSummaryTab extends StatefulWidget {
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
  State<DashboardSummaryTab> createState() => _DashboardSummaryTabState();
}

class _DashboardSummaryTabState extends State<DashboardSummaryTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        // 1. Первичная холодная загрузка: показываем скелетон-каркас вместо спиннера
        if (state is AnalyticsLoading || state is AnalyticsInitial) {
          return const AnalyticsDashboardSkeleton();
        }

        // 2. Ошибка без сохранённых данных
        if (state is AnalyticsError && state.previousMetrics == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Повторить попытку',
                  icon: Icons.refresh,
                  onPressed: () {
                    context.read<AnalyticsBloc>().add(
                          LoadAnalytics(
                            period: widget.selectedPeriod,
                            startDate: widget.startDate,
                            endDate: widget.endDate,
                          ),
                        );
                  },
                ),
              ],
            ),
          );
        }

        // 3. Успешное состояние или фоновое обновление с кэшем
        if (state is AnalyticsLoaded || (state is AnalyticsError && state.previousMetrics != null)) {
          final metrics = state is AnalyticsLoaded
              ? state.metrics
              : (state as AnalyticsError).previousMetrics!;
          final xray = state is AnalyticsLoaded
              ? state.xray
              : (state as AnalyticsError).previousXray!;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardKpiGrid(metrics: metrics),
                  const SizedBox(height: 14),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: RevenueChartCard(timeSeries: metrics.timeSeries),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: CategoryPieChartCard(categories: xray.categories),
                        ),
                      ],
                    )
                  else ...[
                    RevenueChartCard(timeSeries: metrics.timeSeries),
                    const SizedBox(height: 14),
                    CategoryPieChartCard(categories: xray.categories),
                  ],
                  const SizedBox(height: 14),
                  XRayTableCard(items: xray.items),
                  const SizedBox(height: 14),
                ],
              ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
