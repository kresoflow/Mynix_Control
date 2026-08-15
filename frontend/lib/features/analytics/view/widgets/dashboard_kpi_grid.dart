import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';
import 'dashboard_metric_card.dart';

class DashboardKpiGrid extends StatelessWidget {
  final AnalyticsMetrics metrics;

  const DashboardKpiGrid({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final currency = context.watch<SettingsBloc>().state.currency;

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: DashboardMetricCard(
              title: 'Выручка',
              value: '${metrics.totalRevenue.toStringAsFixed(0)} $currency',
              icon: PhosphorIconsRegular.wallet,
              gradientColors: [AppColors.brandPrimary, AppColors.brandSecondary],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DashboardMetricCard(
              title: 'Чистая прибыль',
              value: '${metrics.netProfit.toStringAsFixed(0)} $currency',
              icon: PhosphorIconsRegular.money,
              gradientColors: [AppColors.success, const Color(0xFF34D399)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DashboardMetricCard(
              title: 'Маржинальность',
              value: '${metrics.marginPercentage.toStringAsFixed(1)}%',
              icon: PhosphorIconsRegular.chartLineUp,
              gradientColors: const [Color(0xFF8B5CF6), Color(0xFFC084FC)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DashboardMetricCard(
              title: 'Количество чеков',
              value: '${metrics.totalOrders}',
              icon: PhosphorIconsRegular.receipt,
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardMetricCard(
                title: 'Выручка',
                value: '${metrics.totalRevenue.toStringAsFixed(0)} $currency',
                icon: PhosphorIconsRegular.wallet,
                gradientColors: [AppColors.brandPrimary, AppColors.brandSecondary],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardMetricCard(
                title: 'Чистая прибыль',
                value: '${metrics.netProfit.toStringAsFixed(0)} $currency',
                icon: PhosphorIconsRegular.money,
                gradientColors: [AppColors.success, const Color(0xFF34D399)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardMetricCard(
                title: 'Маржинальность',
                value: '${metrics.marginPercentage.toStringAsFixed(1)}%',
                icon: PhosphorIconsRegular.chartLineUp,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFFC084FC)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardMetricCard(
                title: 'Количество чеков',
                value: '${metrics.totalOrders}',
                icon: PhosphorIconsRegular.receipt,
                gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
