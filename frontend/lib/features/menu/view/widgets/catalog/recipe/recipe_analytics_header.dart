// ==============================================================================
// МОДУЛЬ: Каталог / Финансовая сводка техкарты блюда (KPI Strip)
// ДОМЕН: lib/features/menu/view/widgets/catalog/recipe/recipe_analytics_header.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class RecipeAnalyticsHeader extends StatelessWidget {
  final double totalCost;
  final double price;
  final String currency;

  const RecipeAnalyticsHeader({
    super.key,
    required this.totalCost,
    required this.price,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final margin = price - totalCost;
    final marginPercent = price > 0 ? (margin / price) * 100 : 0.0;
    final foodCostPercent = price > 0 ? (totalCost / price) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: AppKpiCard(
              title: 'Себестоимость',
              value: '${totalCost.toStringAsFixed(2)} $currency',
              icon: PhosphorIconsRegular.scales,
              color: AppColors.danger,
              compact: true,
              subtitle: 'Фудкост: ${foodCostPercent.toStringAsFixed(1)}%',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppKpiCard(
              title: 'Отпускная цена',
              value: '${price.toStringAsFixed(2)} $currency',
              icon: PhosphorIconsRegular.tag,
              color: AppColors.brandPrimary,
              compact: true,
              subtitle: 'В меню продаж',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppKpiCard(
              title: 'Маржа блюда',
              value: '${margin.toStringAsFixed(2)} $currency',
              icon: PhosphorIconsRegular.chartLineUp,
              color: margin >= 0 ? AppColors.success : AppColors.danger,
              compact: true,
              trend: AppKpiTrend(
                label: '${marginPercent.toStringAsFixed(1)}%',
                isPositive: marginPercent >= 40,
                isNeutral: marginPercent >= 15 && marginPercent < 40,
              ),
              subtitle: 'Доход с порции',
            ),
          ),
        ],
      ),
    );
  }
}
