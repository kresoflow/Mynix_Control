import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class IngredientKpiCards extends StatelessWidget {
  final List<Ingredient> ingredients;

  const IngredientKpiCards({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = ingredients.where((i) => !i.isRetail).toList();

    final int totalCount = raw.length;
    int alertCount = 0;
    double totalCost = 0.0;

    for (final item in raw) {
      if (item.isLowStock || item.currentStock <= item.minStockAlert) {
        alertCount++;
      }
      if (item.currentStock > 0) {
        totalCost += (item.currentStock * item.costPerUnit);
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Всего сырья',
            value: '$totalCount поз.',
            icon: PhosphorIconsRegular.package,
            color: AppColors.brandPrimary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: alertCount > 0 ? 'Требуют закупки' : 'Контроль запасов',
            value: alertCount > 0 ? '$alertCount на исходе' : 'В норме',
            icon: alertCount > 0 ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
            color: alertCount > 0 ? AppColors.danger : AppColors.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Себестоимость запасов',
            value: totalCost.toCurrency(context),
            icon: PhosphorIconsRegular.coins,
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
