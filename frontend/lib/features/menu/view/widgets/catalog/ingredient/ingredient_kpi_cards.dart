// ==============================================================================
// МОДУЛЬ: Меню / Каталог / Карточки метрик сырья и ингредиентов (KPI Strip)
// ДОМЕН: lib/features/menu/view/widgets/catalog/ingredient/ingredient_kpi_cards.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ─── 1. Виджет полосы метрик сырья ───────────────────────────────────────────
/// [UI-KIT] Полоса ключевых KPI показателей сырья на базе AppKpiCard.
class IngredientKpiCards extends StatelessWidget {
  final List<Ingredient> ingredients;

  const IngredientKpiCards({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    final raw = ingredients.where((i) => !i.isRetail && !i.isArchived).toList();

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = AppKpiCard(
          title: 'Всего сырья',
          value: '$totalCount поз.',
          icon: PhosphorIconsRegular.package,
          color: AppColors.brandPrimary,
          compact: true,
          subtitle: 'В справочнике ингредиентов',
        );

        final card2 = AppKpiCard(
          title: alertCount > 0 ? 'Требуют закупки' : 'Контроль запасов',
          value: alertCount > 0 ? '$alertCount на исходе' : 'В норме',
          icon: alertCount > 0 ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
          color: alertCount > 0 ? AppColors.danger : AppColors.success,
          compact: true,
          subtitle: alertCount > 0 ? 'Ниже неснижаемого остатка' : 'Все остатки в норме',
        );

        final card3 = AppKpiCard(
          title: 'Себестоимость запасов',
          value: totalCost.toCurrency(context),
          icon: PhosphorIconsRegular.coins,
          color: AppColors.success,
          compact: true,
          subtitle: 'Оценка остатков по себестоимости',
        );

        if (constraints.maxWidth < 600) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 240, child: card1),
                const SizedBox(width: 12),
                SizedBox(width: 240, child: card2),
                const SizedBox(width: 12),
                SizedBox(width: 240, child: card3),
              ],
            ),
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
            const SizedBox(width: 12),
            Expanded(child: card3),
          ],
        );
      },
    );
  }
}
