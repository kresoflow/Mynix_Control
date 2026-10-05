import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';

class DocumentDetailPaymentInfo extends StatelessWidget {
  final InventoryDocument doc;

  const DocumentDetailPaymentInfo({super.key, required this.doc});

  Widget _buildPaymentMethod(String method, bool isDark) {
    IconData icon;
    String label;
    switch (method) {
      case 'cash':
        icon = PhosphorIconsRegular.money;
        label = 'Наличные';
        break;
      case 'transfer':
        icon = PhosphorIconsRegular.arrowsLeftRight;
        label = 'Перевод';
        break;
      case 'card':
        icon = PhosphorIconsRegular.creditCard;
        label = 'Карта';
        break;
      case 'bank_transfer':
        icon = PhosphorIconsRegular.bank;
        label = 'Расчетный счет';
        break;
      default:
        icon = PhosphorIconsRegular.wallet;
        label = method;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
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
    final isReceipt = doc.type == 'receipt';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier / Reason Row
          Row(
            children: [
              Icon(
                isReceipt ? PhosphorIconsRegular.buildings : PhosphorIconsRegular.info,
                size: 16,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isReceipt
                      ? (doc.supplierName ?? 'Без указания поставщика')
                      : (doc.reason ?? 'Причина не указана'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
              if (doc.invoiceNumber != null && doc.invoiceNumber!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    'Накладная: ${doc.invoiceNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                ),
            ],
          ),

          if (isReceipt) ...[
            const SizedBox(height: 10),

            // Payment condition Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Условия расчёта: ',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
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
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    IconData icon;
    String text;

    if (doc.paymentStatus == 'unpaid') {
      color = AppColors.warning;
      icon = PhosphorIconsRegular.clockCounterClockwise;
      text = 'В долг (Постоплата)';
    } else if (doc.paymentStatus == 'paid') {
      color = AppColors.success;
      icon = PhosphorIconsRegular.checkCircle;
      text = 'Оплачено полностью';
    } else {
      final unpaid = doc.totalAmount - doc.paidAmount;
      color = AppColors.info;
      icon = PhosphorIconsRegular.percent;
      text = 'Частично: оплачено ${doc.paidAmount.toCurrency(context)} · долг ${unpaid.toCurrency(context)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(6),
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
