// ==============================================================================
// МОДУЛЬ: POS / Карточка активного столика (PosActiveTableCard)
// ДОМЕН: lib/features/pos/view/widgets/tables/pos_active_table_card.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Карточка открытого столика в зале:
// 1. Отображает таймер выдержки столика с цветовой дифференциацией.
// 2. Индицирует подачу заказа / дозаказа в зал в 1 клик.
// 3. Быстрые действия: Дозаказ, Сплит (разделение счета) и Оплата через AppButton.
// 4. Строго соблюдает стандарты дизайн-системы (AppRadii, AppColors, AppSpacing).
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'pos_active_table_items_view.dart';

// ── 1. Виджет карточки столика ───────────────────────────────────────────────

class PosActiveTableCard extends StatelessWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback onDozakaz;
  final VoidCallback onSplit;
  final VoidCallback onSettle;
  final VoidCallback? onMarkServed;
  final VoidCallback? onCancel;
  final bool isDark;

  const PosActiveTableCard({
    super.key,
    required this.tableData,
    required this.onDozakaz,
    required this.onSplit,
    required this.onSettle,
    this.onMarkServed,
    this.onCancel,
    required this.isDark,
  });

  Color _getTimerColor(int minutes) {
    if (minutes >= 45) return AppColors.danger;
    if (minutes >= 30) return AppColors.warning;
    return AppColors.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final tableNumber = tableData['table_number']?.toString() ?? 'Стол';
    final orderNumber = tableData['order_number'] ?? 0;
    final total = (tableData['total'] as num?)?.toDouble() ?? 0.0;
    final elapsedMinutes = tableData['elapsed_minutes'] as int? ?? 0;
    final status = tableData['status']?.toString().toLowerCase() ?? '';
    final hasDozakaz = tableData['has_dozakaz'] == true;
    final isServed = status == 'ready' && !hasDozakaz;
    final servedItems = (tableData['served_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final dozakazItems = (tableData['dozakaz_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final cleanItems = (tableData['clean_items'] as List?)?.cast<Map<String, dynamic>>() ??
        (tableData['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final timerColor = isServed
        ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
        : _getTimerColor(elapsedMinutes);

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: hasDozakaz
              ? AppColors.warning.withValues(alpha: 0.8)
              : (!isServed && elapsedMinutes >= 35 ? timerColor.withValues(alpha: 0.6) : border),
          width: (hasDozakaz || (!isServed && elapsedMinutes >= 35)) ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Шапка карточки ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIconsBold.chair, color: AppColors.brandPrimary, size: 16),
              ),
              AppSpacing.hSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tableNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    Text(
                      'Заказ #$orderNumber',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              // Таймер выдержки
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.12),
                  borderRadius: AppRadii.radiusSm,
                  border: Border.all(color: timerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.clock, size: 12, color: timerColor),
                    AppSpacing.hXxs,
                    Text(
                      '$elapsedMinutes мин',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: timerColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Статус / Кнопка подачи в зал
              if (isServed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: AppRadii.radiusSm,
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsBold.checkCircle, size: 12, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Подано',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: onMarkServed,
                  borderRadius: AppRadii.radiusSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: AppRadii.radiusSm,
                      border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      hasDozakaz ? 'Отдать дозаказ' : 'Отдать в зал',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ),
              if (onCancel != null) ...[
                const SizedBox(width: 5),
                Tooltip(
                  message: 'Отменить заказ',
                  child: InkWell(
                    onTap: onCancel,
                    borderRadius: AppRadii.radiusSm,
                    child: Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: isDark ? 0.16 : 0.1),
                        borderRadius: AppRadii.radiusSm,
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.trash,
                        size: 14,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          AppSpacing.vSm,
          Divider(color: border, height: 1),
          AppSpacing.vSm,

          // ── Список блюд ──────────────────────────────────────────────────
          Expanded(
            child: PosActiveTableItemsView(
              hasDozakaz: hasDozakaz,
              servedItems: servedItems,
              dozakazItems: dozakazItems,
              cleanItems: cleanItems,
              isDark: isDark,
            ),
          ),
          AppSpacing.vSm,
          Divider(color: border, height: 1),
          AppSpacing.vSm,

          // ── Итого и кнопки действий ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'К оплате:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              Text(
                total.toCurrency(context),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.vSm,
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppSecondaryButton(
                  label: 'Дозаказ',
                  icon: PhosphorIconsBold.plus,
                  size: AppButtonSize.sm,
                  onPressed: onDozakaz,
                ),
              ),
              AppSpacing.hXxs,
              Expanded(
                flex: 3,
                child: AppSecondaryButton(
                  label: 'Сплит',
                  icon: PhosphorIconsBold.scissors,
                  size: AppButtonSize.sm,
                  customColor: AppColors.warning,
                  onPressed: onSplit,
                ),
              ),
              AppSpacing.hXxs,
              Expanded(
                flex: 4,
                child: AppPrimaryButton(
                  label: 'Оплатить',
                  icon: PhosphorIconsBold.creditCard,
                  size: AppButtonSize.sm,
                  onPressed: onSettle,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
