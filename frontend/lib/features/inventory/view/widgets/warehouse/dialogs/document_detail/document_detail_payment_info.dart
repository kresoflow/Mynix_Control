import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';

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
      case 'card':
        icon = PhosphorIconsRegular.creditCard;
        label = 'Банковская карта';
        break;
      case 'bank_transfer':
        icon = PhosphorIconsRegular.bank;
        label = 'Расчетный счет';
        break;
      default:
        icon = PhosphorIconsRegular.wallet;
        label = method;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.brandPrimary),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ],
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier / Reason Row
          Row(
            children: [
              Icon(
                isReceipt ? PhosphorIconsRegular.buildings : PhosphorIconsRegular.info,
                size: 15,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Накладная: ${doc.invoiceNumber}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                  children: [
                    Text(
                      'Условия расчёта: ',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
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
    if (doc.paymentStatus == 'unpaid') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.clockCounterClockwise, size: 11, color: AppColors.warning),
            SizedBox(width: 4),
            Text(
              'В долг (Постоплата)',
              style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (doc.paymentStatus == 'paid') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.checkCircle, size: 11, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Оплачено сразу',
              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      final unpaid = doc.totalAmount - doc.paidAmount;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Частично (Оплачено: ${doc.paidAmount.toCurrency(context)}, Долг: ${unpaid.toCurrency(context)})',
          style: const TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}
