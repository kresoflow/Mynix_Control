// ==============================================================================
// МОДУЛЬ: Склад / Сводка ключевых метрик остатков (KPI Header)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock/stock_metrics_header.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

// ─── 1. Виджет полосы метрик остатков склада ─────────────────────────────────
/// [UI-KIT] Полоса ключевых KPI показателей складского учета на базе AppKpiCard.
class StockMetricsHeader extends StatelessWidget {
  final int totalCount;
  final int lowStockCount;
  final double totalCapital;
  final double potentialRevenue;
  final double expectedProfit;

  const StockMetricsHeader({
    super.key,
    required this.totalCount,
    required this.lowStockCount,
    required this.totalCapital,
    required this.potentialRevenue,
    required this.expectedProfit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1150;
          final isMedium = constraints.maxWidth >= 700;

          final card1 = AppKpiCard(
            title: 'Всего позиций',
            value: '$totalCount шт.',
            icon: PhosphorIconsRegular.package,
            color: AppColors.brandPrimary,
            compact: true,
            subtitle: 'Активная номенклатура',
          );

          final card2 = AppKpiCard(
            title: 'Вложено (Опт)',
            value: totalCapital.toCurrency(context),
            icon: PhosphorIconsRegular.wallet,
            color: AppColors.brandSecondary,
            compact: true,
            subtitle: 'Себестоимость склада',
          );

          final card3 = AppKpiCard(
            title: 'В рознице',
            value: potentialRevenue.toCurrency(context),
            icon: PhosphorIconsRegular.trendUp,
            color: AppColors.info,
            compact: true,
            subtitle: 'Оценка по прайс-листу',
          );

          final card4 = AppKpiCard(
            title: 'Ожид. прибыль',
            value: expectedProfit.toCurrency(context),
            icon: PhosphorIconsRegular.money,
            color: AppColors.success,
            compact: true,
            subtitle: 'Маржинальный доход',
          );

          final card5 = AppKpiCard(
            title: 'На исходе',
            value: '$lowStockCount поз.',
            icon: PhosphorIconsRegular.warningCircle,
            color: lowStockCount > 0 ? AppColors.danger : AppColors.success,
            compact: true,
            subtitle: lowStockCount > 0 ? 'Ниже минимума' : 'В норме',
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
                const SizedBox(width: 12),
                Expanded(child: card3),
                const SizedBox(width: 12),
                Expanded(child: card4),
                const SizedBox(width: 12),
                Expanded(child: card5),
              ],
            );
          }

          if (isMedium) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 12),
                    Expanded(child: card2),
                    const SizedBox(width: 12),
                    Expanded(child: card3),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: card4),
                    const SizedBox(width: 12),
                    Expanded(child: card5),
                  ],
                ),
              ],
            );
          }

          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
              const SizedBox(height: 10),
              card3,
              const SizedBox(height: 10),
              card4,
              const SizedBox(height: 10),
              card5,
            ],
          );
        },
      ),
    );
  }
}
