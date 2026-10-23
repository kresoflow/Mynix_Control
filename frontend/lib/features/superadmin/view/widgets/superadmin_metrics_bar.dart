// ============================================================================
// Kreso Flow | Superadmin View | Metrics Bar Widget
// ============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

// ─── 1. Metrics Bar Component ───────────────────────────────────────────────

class SuperadminMetricsBar extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final bool isDark;

  const SuperadminMetricsBar({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
      child: Row(
        children: [
          _buildMetricCard(
            'Всего точек',
            '$totalCount',
            PhosphorIconsRegular.storefront,
            AppColors.brandPrimary,
          ),
          const SizedBox(width: 16),
          _buildMetricCard(
            'Активных точек',
            '$activeCount',
            PhosphorIconsRegular.checkCircle,
            AppColors.success,
          ),
          const SizedBox(width: 16),
          _buildMetricCard(
            'PostgreSQL Schemas',
            '$totalCount',
            PhosphorIconsRegular.database,
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String val,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: AppRadii.radiusXl,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadii.inputRadius,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                Text(val, style: AppTextStyles.h2.copyWith(fontSize: 20)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
