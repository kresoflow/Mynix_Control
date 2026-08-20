import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/models/customer_transaction.dart';
import 'customer_statement_pdf_service.dart';

class CustomerLedgerTab extends StatelessWidget {
  final Customer customer;
  final List<CustomerTransaction> transactions;
  final VoidCallback onOpenPayment;

  const CustomerLedgerTab({
    super.key,
    required this.customer,
    required this.transactions,
    required this.onOpenPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = CurrencyFormatter.symbol(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onOpenPayment,
              icon: const Icon(PhosphorIconsRegular.money, size: 18),
              label: Text(customer.balance < 0 ? 'Принять оплату долга' : 'Внести депозит'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customer.balance < 0 ? AppColors.brandPrimary : AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => CustomerStatementPdfService.downloadStatement(customer, transactions, symbol),
              icon: Icon(PhosphorIconsRegular.filePdf, size: 18, color: AppColors.brandPrimary),
              label: Text('Акт сверки (PDF)', style: TextStyle(color: AppColors.brandPrimary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: AppColors.brandPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text(
                    'История сальдо пуста',
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                )
              : ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  itemBuilder: (context, index) {
                    final txn = transactions[index];
                    final isDebit = txn.type == CustomerTransactionType.orderDebt;
                    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(txn.date);
                    final methodLabel = txn.paymentMethod == 'transfer' ? 'Перевод' : (txn.paymentMethod == 'cash' ? 'Наличные' : txn.paymentMethod);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isDebit ? PhosphorIconsRegular.shoppingBag : PhosphorIconsRegular.arrowDownLeft,
                            color: isDebit ? AppColors.error : AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(txn.type.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                  '$dateStr • $methodLabel${txn.comment != null ? ' • ${txn.comment}' : ''}',
                                  style: TextStyle(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isDebit ? '-' : '+'} ${txn.amount.toStringAsFixed(2)} $symbol',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDebit ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
