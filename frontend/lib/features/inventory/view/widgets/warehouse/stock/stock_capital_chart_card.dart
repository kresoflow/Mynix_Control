import 'package:flutter/material.dart';
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
                  PhosphorIconsRegular.chartBarHorizontal,
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
                      'Структура капитала',
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
          const SizedBox(height: 14),
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
            // 1. Сегментированная полоса распределения капитала
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: topEntries.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final pct = (item.value / totalCapital) * 100;
                    final color = colors[idx % colors.length];

                    return Expanded(
                      flex: (pct * 10).round().clamp(1, 1000),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        color: color,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Список категорий с бейджами долей и суммами
            ...topEntries.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final color = colors[idx % colors.length];
              final pct = (item.value / totalCapital) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.value.toCurrency(context),
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
