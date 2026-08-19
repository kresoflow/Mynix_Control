import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/models/supplier_transaction.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SupplierSettlementRow extends StatelessWidget {
  final SupplierTransaction transaction;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SupplierSettlementRow({
    super.key,
    required this.transaction,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isInvoice = transaction.type == SupplierTransactionType.invoice;
    final isPayment = transaction.type == SupplierTransactionType.payment;

    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(transaction.date.toLocal());
    final Color amountColor = isPayment ? AppColors.success : AppColors.danger;
    final String amountSign = isPayment ? '- ' : '+ ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPayment
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPayment
                  ? PhosphorIconsRegular.arrowDownLeft
                  : isInvoice
                      ? PhosphorIconsRegular.fileText
                      : PhosphorIconsRegular.warningCircle,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),

          // Date & Type
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext, fontSize: 11),
                ),
              ],
            ),
          ),

          // Comment / Document info
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.comment ?? (isInvoice ? 'Приходная накладная #${transaction.documentId}' : '-'),
                  style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.darkText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isPayment) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatPaymentMethod(transaction.paymentMethod),
                    style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),

          // Amount
          Expanded(
            flex: 3,
            child: Text(
              '$amountSign${transaction.amount.toStringAsFixed(2)} $currency',
              style: AppTextStyles.h3.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          const SizedBox(width: 16),

          // Actions
          if (!isInvoice) ...[
            IconButton(
              icon: Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: AppColors.darkSubtext),
              onPressed: onEdit,
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
              onPressed: onDelete,
              tooltip: 'Удалить операцию',
            ),
          ] else
            const SizedBox(width: 72),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'cash':
        return 'Наличные';
      case 'card':
        return 'Карта';
      case 'bank_transfer':
        return 'Перевод / Р/С';
      default:
        return method;
    }
  }
}
