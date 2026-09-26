// ==============================================================================
// МОДУЛЬ: Склад / Заголовок подкатегории остатков (Stock Subcategory Header)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock/stock_subcategory_header.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ─── 1. Виджет заголовка подкатегории ────────────────────────────────────────

class StockSubcategoryHeader extends StatelessWidget {
  final String subcategoryName;
  final List<Ingredient> items;
  final bool isExpanded;
  final VoidCallback onTap;

  const StockSubcategoryHeader({
    super.key,
    required this.subcategoryName,
    required this.items,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalCapital = 0;
    int lowStockCount = 0;
    for (var item in items) {
      if (item.currentStock > 0) {
        totalCapital += item.currentStock * item.costPerUnit;
      }
      if (item.isLowStock || item.currentStock <= 0) {
        lowStockCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: isExpanded
              ? AppColors.brandPrimary.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? PhosphorIconsRegular.folderOpen
                      : PhosphorIconsRegular.folder,
                  size: 16,
                  color: isExpanded
                      ? AppColors.brandPrimary
                      : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subcategoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isExpanded
                          ? AppColors.brandPrimary
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                ),
                if (lowStockCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      '$lowStockCount!',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${items.length} поз.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Σ ${totalCapital.toCurrency(context)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    PhosphorIconsRegular.caretDown,
                    size: 14,
                    color: isExpanded
                        ? AppColors.brandPrimary
                        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
