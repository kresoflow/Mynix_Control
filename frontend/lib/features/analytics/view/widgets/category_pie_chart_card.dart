import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';

class CategoryPieChartCard extends StatelessWidget {
  final List<CategorySales> categories;

  const CategoryPieChartCard({
    super.key,
    required this.categories,
  });

  static final List<Color> chartColors = [
    AppColors.brandPrimary,
    const Color(0xFF34D399),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF3B82F6),
  ];

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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 24),
          if (categories.isEmpty)
            Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
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
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: categories.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          return PieChartSectionData(
            color: chartColors[index % chartColors.length],
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
                color: chartColors[index % chartColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.categoryName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${item.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        );
      },
    );
  }
}
