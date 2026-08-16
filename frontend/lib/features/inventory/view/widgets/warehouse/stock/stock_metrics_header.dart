import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/analytics/view/widgets/dashboard_metric_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

          final card1 = DashboardMetricCard(
            title: 'Всего позиций',
            value: '$totalCount шт.',
            icon: PhosphorIconsRegular.package,
            gradientColors: [AppColors.brandTertiary, const Color(0xFF00B4D8)],
          );

          final card2 = DashboardMetricCard(
            title: 'Вложено (Опт)',
            value: totalCapital.toCurrency(context),
            icon: PhosphorIconsRegular.wallet,
            gradientColors: [AppColors.brandPrimary, AppColors.brandSecondary],
          );

          final card3 = DashboardMetricCard(
            title: 'В рознице',
            value: potentialRevenue.toCurrency(context),
            icon: PhosphorIconsRegular.trendUp,
            gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          );

          final card4 = DashboardMetricCard(
            title: 'Ожид. Прибыль',
            value: expectedProfit.toCurrency(context),
            icon: PhosphorIconsRegular.money,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
          );

          final card5 = DashboardMetricCard(
            title: 'На исходе',
            value: '$lowStockCount поз.',
            icon: PhosphorIconsRegular.warningCircle,
            gradientColors: lowStockCount > 0
                ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                : const [Color(0xFF64748B), Color(0xFF475569)],
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
