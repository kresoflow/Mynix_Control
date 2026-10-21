// ==============================================================================
// МОДУЛЬ: Аналитика / KPI карточки сводки кассовых смен
// ДОМЕН: lib/features/analytics/view/widgets/shift_history_kpi_cards.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

/// [UI-KIT] Блок KPI карточек для вкладки истории кассовых смен
class ShiftHistoryKpiCards extends StatelessWidget {
  final int totalCount;
  final double totalRevenue;
  final double totalDiscrepancy;

  const ShiftHistoryKpiCards({
    super.key,
    required this.totalCount,
    required this.totalRevenue,
    required this.totalDiscrepancy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppKpiCard(
            title: 'Всего смен в журнале',
            value: '$totalCount',
            icon: PhosphorIconsRegular.clockCounterClockwise,
            color: AppColors.brandPrimary,
            subtitle: 'Закрытые смены за период',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AppKpiCard(
            title: 'Суммарная выручка',
            value: totalRevenue.toCurrency(context),
            icon: PhosphorIconsRegular.chartLineUp,
            color: AppColors.success,
            subtitle: 'Выручка всех смен',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AppKpiCard(
            title: 'Чистое расхождение кассы',
            value: totalDiscrepancy == 0
                ? '0 с (Точно)'
                : (totalDiscrepancy < 0
                    ? totalDiscrepancy.toCurrency(context)
                    : '+${totalDiscrepancy.toCurrency(context)}'),
            icon: PhosphorIconsRegular.scales,
            color: totalDiscrepancy == 0
                ? AppColors.success
                : (totalDiscrepancy < 0 ? AppColors.danger : AppColors.warning),
            subtitle: totalDiscrepancy == 0
                ? 'Без расхождений'
                : (totalDiscrepancy < 0 ? 'Недостача в кассе' : 'Излишек в кассе'),
          ),
        ),
      ],
    );
  }
}
