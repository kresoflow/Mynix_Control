// ==============================================================================
// МОДУЛЬ: Аналитика / Стандартизированная строка таблицы кассовых смен
// ДОМЕН: lib/features/analytics/view/widgets/analytics_shift_row.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'dialogs/shift_history_details_dialog.dart';

/// [UI-KIT] Интерактивная строка таблицы истории смен (AppDataTableRow)
class AnalyticsShiftRow extends StatelessWidget {
  final Map<String, dynamic> shift;
  final List<AppDataTableColumn> columns;

  const AnalyticsShiftRow({
    super.key,
    required this.shift,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shiftId = shift['id'];
    final isOpen = shift['is_open'] == true;
    final totalRev = (shift['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final diff = (shift['discrepancy'] as num?)?.toDouble();
    final openingCash = (shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = shift['orders_count'] ?? 0;
    final itemsCount = shift['items_sold_count'] ?? 0;
    final openedBy = shift['opened_by_name'] ?? 'Кассир';

    String openedStr = '-';
    if (shift['opened_at'] != null) {
      final p = DateTime.tryParse(shift['opened_at'].toString());
      if (p != null) openedStr = DateFormat('dd.MM, HH:mm').format(p.toLocal());
    }

    String closedStr = '-';
    if (shift['closed_at'] != null) {
      final p = DateTime.tryParse(shift['closed_at'].toString());
      if (p != null) closedStr = DateFormat('dd.MM, HH:mm').format(p.toLocal());
    }

    return AppDataTableRow(
      columns: columns,
      horizontalPadding: 16,
      minHeight: 56,
      onTap: () => ShiftHistoryDetailsDialog.show(context, shift),
      children: [
        // 0. Аватар / Идентификатор смены
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isOpen
                  ? AppColors.success.withValues(alpha: 0.5)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$shiftId',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
        ),

        // 1. Смена и кассир
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.success : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      openedBy,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                isOpen ? 'Открыта: $openedStr (Активна)' : '$openedStr → $closedStr',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ],
          ),
        ),

        // 2. Размен и количество продаж
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${openingCash.toCurrency(context)} размен',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$ordersCount заказов • $itemsCount поз.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ],
          ),
        ),

        // 3. Суммарная выручка
        Text(
          totalRev.toCurrency(context),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),

        // 4. Результат кассы (Унифицированный бейдж UI Kit)
        isOpen || diff == null
            ? const AppStatusBadge(
                label: 'Активна',
                variant: AppBadgeVariant.success,
                hasDot: true,
              )
            : (diff == 0
                ? const AppStatusBadge(
                    label: 'Точно (0 с)',
                    variant: AppBadgeVariant.success,
                    icon: PhosphorIconsRegular.checkCircle,
                  )
                : (diff < 0
                    ? AppStatusBadge(
                        label: 'Недостача: ${diff.toCurrency(context)}',
                        variant: AppBadgeVariant.danger,
                        icon: PhosphorIconsRegular.warningCircle,
                      )
                    : AppStatusBadge(
                        label: 'Излишек: +${diff.toCurrency(context)}',
                        variant: AppBadgeVariant.warning,
                        icon: PhosphorIconsRegular.warningCircle,
                      ))),

        // 5. Иконка перехода к деталям
        Icon(
          PhosphorIconsRegular.caretRight,
          size: 16,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
      ],
    );
  }
}
