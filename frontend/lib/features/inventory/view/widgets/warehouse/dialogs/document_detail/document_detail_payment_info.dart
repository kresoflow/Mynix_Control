import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';

class DocumentDetailPaymentInfo extends StatelessWidget {
  final InventoryDocument doc;

  const DocumentDetailPaymentInfo({super.key, required this.doc});

  Widget _buildSimpleInfoBar({
    required IconData icon,
    required String label,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: AppRadii.badgeRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: color,),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String method, bool isDark) {
    final (icon, label) = switch (method) {
      'cash' => (PhosphorIconsRegular.money, 'Наличные'),
      'transfer' => (PhosphorIconsRegular.arrowsLeftRight, 'Перевод'),
      'card' => (PhosphorIconsRegular.creditCard, 'Карта'),
      'bank_transfer' => (PhosphorIconsRegular.bank, 'Расчетный счет'),
      _ => (PhosphorIconsRegular.wallet, method),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (doc.type == 'write_off') {
      return _buildSimpleInfoBar(
        icon: PhosphorIconsRegular.archive,
        label: 'Причина списания',
        color: AppColors.danger,
        text:
            doc.reason?.isNotEmpty == true ? doc.reason! : 'Порча / Просрочка',
        isDark: isDark,
      );
    }

    if (doc.type == 'inventory') {
      return _buildSimpleInfoBar(
        icon: PhosphorIconsRegular.clipboardText,
        label: 'Ревизия склада',
        color: AppColors.brandPrimary,
        text: doc.reason?.isNotEmpty == true
            ? doc.reason!
            : 'Слепая инвентаризация',
        isDark: isDark,
      );
    }

    // Default: Receipt
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.buildings,
                  size: 16, color: AppColors.brandPrimary,),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doc.supplierName ?? 'Без указания поставщика',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
              if (doc.invoiceNumber != null && doc.invoiceNumber!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                    borderRadius: AppRadii.badgeRadius,
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    'Накладная: ${doc.invoiceNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Условия расчёта: ',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildPaymentBadge(context),
                ],
              ),
              if (doc.paymentStatus != 'unpaid')
                _buildPaymentMethod(doc.paymentMethod, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unpaid = doc.totalAmount - doc.paidAmount;
    final (color, icon, text) = switch (doc.paymentStatus) {
      'unpaid' => (
          AppColors.warning,
          PhosphorIconsRegular.clockCounterClockwise,
          'В долг (Постоплата)',
        ),
      'paid' => (
          AppColors.success,
          PhosphorIconsRegular.checkCircle,
          'Оплачено полностью',
        ),
      _ => (
          AppColors.info,
          PhosphorIconsRegular.percent,
          'Частично: оплачено ${doc.paidAmount.toCurrency(context)} · долг ${unpaid.toCurrency(context)}',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: AppRadii.badgeRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
