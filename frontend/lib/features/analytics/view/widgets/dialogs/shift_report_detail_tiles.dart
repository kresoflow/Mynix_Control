// ==============================================================================
// Title: ShiftReportDetailTiles (shift_report_detail_tiles.dart)
// Path: frontend/lib/features/analytics/view/widgets/dialogs/shift_report_detail_tiles.dart
// Description: Вспомогательные строки и плашки детализации Z-отчета смены.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';

// ─── 1. Карточка-контейнер для группы показателей ─────────────────────────────

Widget buildShiftInfoTile(bool isDark, List<Widget> children) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: AppRadii.inputRadius,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
}

// ─── 2. Универсальная строка показателя ───────────────────────────────────────

Widget buildShiftDetailRow(
  String label,
  String value,
  bool isDark, {
  bool isBold = false,
  Color? color,
  IconData? icon,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color ?? (isDark ? AppColors.darkText : AppColors.lightText),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 13 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}

// ─── 3. Строка статуса смены ──────────────────────────────────────────────────

Widget buildShiftStatusRow(bool isOpen, bool isDark) {
  final color = isOpen
      ? AppColors.success
      : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Статус:',
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            fontSize: 12,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              isOpen ? 'Активна' : 'Закрыта',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─── 4. Строка расхождения фактической кассы (Discrepancy) ───────────────────

Widget buildShiftDiscrepancyRow(double diff, bool isDark, BuildContext context) {
  final color = diff == 0
      ? AppColors.success
      : (diff < 0 ? AppColors.danger : AppColors.warning);
  final text = diff == 0
      ? 'Точно (0 с)'
      : (diff < 0
          ? 'Недостача: ${diff.toCurrency(context)}'
          : 'Излишек: +${diff.toCurrency(context)}');

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Результат кассы:',
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            fontSize: 12,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadii.badgeRadius,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                diff == 0
                    ? PhosphorIconsRegular.checkCircle
                    : PhosphorIconsRegular.warningCircle,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
