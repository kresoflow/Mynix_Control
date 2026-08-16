import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
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

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required PhosphorIconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Всего позиций',
                  value: totalCount.toString(),
                  icon: PhosphorIconsRegular.package,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Позиций на исходе',
                  value: lowStockCount.toString(),
                  icon: PhosphorIconsRegular.warningCircle,
                  color: lowStockCount > 0 ? AppColors.danger : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Вложено (Опт)',
                  value: totalCapital.toCurrency(context),
                  icon: PhosphorIconsRegular.wallet,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Потенциал (Розница)',
                  value: potentialRevenue.toCurrency(context),
                  icon: PhosphorIconsRegular.trendUp,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Ожид. Прибыль',
                  value: expectedProfit.toCurrency(context),
                  icon: PhosphorIconsRegular.money,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
