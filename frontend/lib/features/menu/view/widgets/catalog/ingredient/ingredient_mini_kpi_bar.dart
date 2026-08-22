import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class IngredientMiniKpiBar extends StatelessWidget {
  final List<Ingredient> ingredients;

  const IngredientMiniKpiBar({super.key, required this.ingredients});

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131824) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Total Positions
          _buildKpiChip(
            icon: PhosphorIconsRegular.package,
            iconColor: AppColors.brandPrimary,
            label: '$totalCount поз. сырья',
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Low Stock Alert
          _buildKpiChip(
            icon: alertCount > 0 ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
            iconColor: alertCount > 0 ? AppColors.danger : AppColors.success,
            label: alertCount > 0 ? '$alertCount на исходе' : 'Запасы в норме',
            isHighlighted: alertCount > 0,
            highlightColor: AppColors.danger,
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Total Stock Value
          _buildKpiChip(
            icon: PhosphorIconsRegular.coins,
            iconColor: AppColors.success,
            label: 'На складе: ${totalCost.toCurrency(context)}',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    bool isHighlighted = false,
    Color? highlightColor,
    required bool isDark,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (highlightColor ?? AppColors.danger).withValues(alpha: 0.12)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlighted
              ? (highlightColor ?? AppColors.danger).withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlighted
                  ? (highlightColor ?? AppColors.danger)
                  : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
        ],
      ),
    );
  }
}
