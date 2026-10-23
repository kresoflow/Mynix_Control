// ==============================================================================
// МОДУЛЬ: POS / Колонка гостя при разделении счета (PosSplitBillGuestColumn)
// ДОМЕН: lib/features/pos/view/widgets/tables/split_bill_guest_column.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Колонка позиций гостя для модального окна сплит-чека:
// 1. Отображает список назначенных позиций гостя с кнопками переноса.
// 2. Отображает итоговую сумму чека гостя.
// 3. Содержит кнопку быстрой оплаты данного чека через AppPrimaryButton.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';

// ── 1. Колонка позиций конкретного гостя ──────────────────────────────────────

class PosSplitBillGuestColumn extends StatelessWidget {
  final int index;
  final List<Map<String, dynamic>> items;
  final double total;
  final Color border;
  final bool isDark;
  final bool isProcessing;
  final ValueChanged<Map<String, dynamic>> onMove;
  final VoidCallback onPay;
  final bool isLeft;

  const PosSplitBillGuestColumn({
    super.key,
    required this.index,
    required this.items,
    required this.total,
    required this.border,
    required this.isDark,
    required this.isProcessing,
    required this.onMove,
    required this.onPay,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsBold.user,
                    size: 16,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Гость $index (Чек #$index)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ],
              ),
              Text(
                total.toCurrency(context),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.brandPrimary, fontSize: 15),
              ),
            ],
          ),
          AppSpacing.vSm,
          Divider(color: border, height: 1),
          AppSpacing.vSm,
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Чек пуст',
                      style: TextStyle(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      final name = it['menu_item_name'] ?? '';
                      final qty = it['quantity'] ?? 1;
                      final price = (it['unit_price'] as num?)?.toDouble() ?? 0.0;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$name × $qty',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            (price * qty).toCurrency(context),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => onMove(it),
                            borderRadius: AppRadii.radiusXs,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                                borderRadius: AppRadii.radiusXs,
                              ),
                              child: Icon(
                                isLeft ? PhosphorIconsBold.arrowRight : PhosphorIconsBold.arrowLeft,
                                size: 14,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          AppSpacing.vSm,
          AppPrimaryButton(
            onPressed: items.isEmpty || isProcessing ? null : onPay,
            icon: PhosphorIconsBold.creditCard,
            label: items.isEmpty
                ? 'Чек оплачен или пуст'
                : 'Оплатить Чек $index (${total.toCurrency(context)})',
            size: AppButtonSize.md,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
