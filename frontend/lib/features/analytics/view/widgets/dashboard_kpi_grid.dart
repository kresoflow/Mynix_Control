// ==============================================================================
// МОДУЛЬ: Аналитика / Сетка ключевых KPI показателей дашборда
// ДОМЕН: lib/features/analytics/view/widgets/dashboard_kpi_grid.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/features/analytics/models/analytics_models.dart';

// ─── 1. Виджет сетки KPI аналитики ───────────────────────────────────────────
/// [UI-KIT] Адаптивная сетка ключевых метрик аналитического дашборда на базе AppKpiCard.
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

    final cardRevenue = AppKpiCard(
      title: 'Выручка',
      value: '${metrics.totalRevenue.toStringAsFixed(0)} $currency',
      icon: PhosphorIconsRegular.wallet,
      color: AppColors.brandPrimary,
      compact: !isDesktop,
      subtitle: 'Оборот за период',
    );

    final cardProfit = AppKpiCard(
      title: 'Чистая прибыль',
      value: '${metrics.netProfit.toStringAsFixed(0)} $currency',
      icon: PhosphorIconsRegular.money,
      color: AppColors.success,
      compact: !isDesktop,
      subtitle: 'Доход за вычетом расходов',
    );

    final cardMargin = AppKpiCard(
      title: 'Маржинальность',
      value: '${metrics.marginPercentage.toStringAsFixed(1)}%',
      icon: PhosphorIconsRegular.chartLineUp,
      color: AppColors.brandSecondary,
      compact: !isDesktop,
      subtitle: 'Рентабельность продаж',
    );

    final cardOrders = AppKpiCard(
      title: 'Количество чеков',
      value: '${metrics.totalOrders}',
      icon: PhosphorIconsRegular.receipt,
      color: AppColors.info,
      compact: !isDesktop,
      subtitle: 'Закрытых заказов',
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: cardRevenue),
          const SizedBox(width: 16),
          Expanded(child: cardProfit),
          const SizedBox(width: 16),
          Expanded(child: cardMargin),
          const SizedBox(width: 16),
          Expanded(child: cardOrders),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cardRevenue),
            const SizedBox(width: 12),
            Expanded(child: cardProfit),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cardMargin),
            const SizedBox(width: 12),
            Expanded(child: cardOrders),
          ],
        ),
      ],
    );
  }
}
