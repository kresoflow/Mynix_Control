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

    final topEntries = entries.take(5).toList();
    final otherValue = entries.skip(5).fold(0.0, (sum, e) => sum + e.value);
    if (otherValue > 0) {
      topEntries.add(MapEntry('Прочее', otherValue));
    }

    final colors = [
      AppColors.brandPrimary,
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFF00B4D8),
      const Color(0xFFEC4899),
      const Color(0xFF94A3B8),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIconsRegular.chartPieSlice,
                  color: AppColors.brandPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Капитал по категориям',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Всего: ${totalCapital.toCurrency(context)}',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topEntries.isEmpty || totalCapital <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Нет данных о стоимости остатков',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 130,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: topEntries.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final pct = (item.value / totalCapital) * 100;
                    return PieChartSectionData(
                      color: colors[idx % colors.length],
                      value: item.value,
                      title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                      radius: 24,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...topEntries.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final color = colors[idx % colors.length];
              final pct = (item.value / totalCapital) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.key,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}% (${item.value.toCurrency(context)})',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        fontSize: 11,
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
