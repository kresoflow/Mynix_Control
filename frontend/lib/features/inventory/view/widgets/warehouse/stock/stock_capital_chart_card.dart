import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StockCapitalChartCard extends StatelessWidget {
  final Map<String, double> categoryCapitals;
  final double totalCapital;

  const StockCapitalChartCard({
    super.key,
    required this.categoryCapitals,
    required this.totalCapital,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = categoryCapitals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = entries.take(4).toList();
    final otherValue = entries.skip(4).fold(0.0, (sum, e) => sum + e.value);
    if (otherValue > 0) {
      topEntries.add(MapEntry('Прочее', otherValue));
    }

    final colors = [
      AppColors.brandPrimary,
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFF00B4D8),
      const Color(0xFF94A3B8),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  PhosphorIconsRegular.chartPieSlice,
                  color: AppColors.brandPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Капитал по категориям',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Всего: ${totalCapital.toCurrency(context)}',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topEntries.isEmpty || totalCapital <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Нет данных об остатках',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 100,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 28,
                  sections: topEntries.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final pct = (item.value / totalCapital) * 100;
                    return PieChartSectionData(
                      color: colors[idx % colors.length],
                      value: item.value,
                      title: pct >= 12 ? '${pct.toStringAsFixed(0)}%' : '',
                      radius: 20,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...topEntries.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final color = colors[idx % colors.length];
              final pct = (item.value / totalCapital) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.key,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}% (${item.value.toCurrency(context)})',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
