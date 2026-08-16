import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/analytics/models/analytics_models.dart';

class RevenueChartCard extends StatelessWidget {
  final List<TimeSeriesPoint> timeSeries;

  const RevenueChartCard({
    super.key,
    required this.timeSeries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      height: isDesktop ? 400 : 320,
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
            'Динамика выручки',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: timeSeries.isEmpty
                ? Center(
                    child: Text(
                      'Нет данных за период',
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) => _buildBottomTitle(value, timeSeries, isDark),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _getInterval(timeSeries),
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) => _buildLeftTitle(value, isDark),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: timeSeries.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.revenue);
                          }).toList(),
                          isCurved: true,
                          color: AppColors.brandPrimary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.brandPrimary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTitle(double value, List<TimeSeriesPoint> timeSeries, bool isDark) {
    if (value.toInt() >= 0 && value.toInt() < timeSeries.length) {
      if (timeSeries.length > 10 && value.toInt() % (timeSeries.length ~/ 5) != 0) {
        return const SizedBox.shrink();
      }
      String label = timeSeries[value.toInt()].timestamp;
      if (label.contains(' ')) {
        label = label.split(' ')[1];
      } else if (label.length == 10) {
        final parts = label.split('-');
        label = '${parts[2]}.${parts[1]}';
      } else if (label.length == 7) {
        final parts = label.split('-');
        label = '${parts[1]}.${parts[0]}';
      }

      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            fontSize: 10,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLeftTitle(double value, bool isDark) {
    if (value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        _formatCompact(value),
        style: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
      ),
    );
  }

  double _getInterval(List<TimeSeriesPoint> data) {
    if (data.isEmpty) return 1000;
    final double max = data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
    if (max == 0) return 1000;
    return max / 4;
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
