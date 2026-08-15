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
    final currency = context.read<SettingsBloc>().state.currency;
    final isDesktop = MediaQuery.of(context).size.width > 1100;

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
              gradientColors: [AppColors.success, AppColors.brandTertiary],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DashboardMetricCard(
              title: 'Маржинальность',
              value: '${metrics.marginPercentage.toStringAsFixed(1)}%',
              icon: PhosphorIconsRegular.chartLineUp,
              gradientColors: [AppColors.brandSecondary, AppColors.brandPrimary],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DashboardMetricCard(
              title: 'Количество чеков',
              value: '${metrics.totalOrders}',
              icon: PhosphorIconsRegular.receipt,
              gradientColors: [AppColors.info, AppColors.brandTertiary],
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
                gradientColors: [AppColors.success, AppColors.brandTertiary],
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
                gradientColors: [AppColors.brandSecondary, AppColors.brandPrimary],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardMetricCard(
                title: 'Количество чеков',
                value: '${metrics.totalOrders}',
                icon: PhosphorIconsRegular.receipt,
                gradientColors: [AppColors.info, AppColors.brandTertiary],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
