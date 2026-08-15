import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';

class CategoryPieChartCard extends StatelessWidget {
  final List<CategorySales> categories;

  const CategoryPieChartCard({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      height: isDesktop ? 400 : null,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Продажи по категориям',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 24),
          if (categories.isEmpty)
            Center(
              child: Text(
                'Нет данных',
                style: AppTextStyles.body.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            )
          else if (isDesktop)
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildPieChart()),
                  const SizedBox(width: 16),
                  Expanded(child: Center(child: _buildLegend(isDark))),
                ],
              ),
            )
          else
            Column(
              children: [
                SizedBox(height: 200, child: _buildPieChart()),
                const SizedBox(height: 24),
                _buildLegend(isDark),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final colors = AppColors.chartPalette;
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: categories.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: item.percentage,
            title: '${item.percentage.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    final colors = AppColors.chartPalette;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = categories[index];
        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.categoryName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${item.percentage.toStringAsFixed(1)}%',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ],
        );
      },
    );
  }
}
