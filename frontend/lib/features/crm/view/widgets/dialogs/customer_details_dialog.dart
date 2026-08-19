import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/models/customer_transaction.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_bloc.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_event.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_state.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_statement_pdf_service.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_payment_modal.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_bonus_tab.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_orders_tab.dart';

class CustomerDetailsDialog extends StatefulWidget {
  final Customer customer;
  final VoidCallback onEdit;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
    required this.onEdit,
  });

  @override
  State<CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog> {
  int _activeTab = 0; // 0 = Orders, 1 = Ledger, 2 = Bonus & LTV

  @override
  void initState() {
    super.initState();
    context.read<CrmBloc>().add(LoadCustomerOrdersEvent(widget.customer.id));
    context.read<CrmBloc>().add(LoadCustomerTransactionsEvent(widget.customer.id));
  }

  void _openPaymentModal(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (_) => CustomerPaymentModal(
        customer: customer,
        onSubmit: (data) {
          context.read<CrmBloc>().add(CreateCustomerTransactionEvent(customer.id, data));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocBuilder<CrmBloc, CrmState>(
      builder: (context, state) {
        Customer currentCustomer = widget.customer;
        List<CustomerTransaction> transactions = [];

        if (state is CrmLoaded) {
          final found = state.customers.where((c) => c.id == widget.customer.id);
          if (found.isNotEmpty) currentCustomer = found.first;
          transactions = state.transactionsCache[widget.customer.id] ?? [];
        }

        return Dialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(PhosphorIconsRegular.userCheck, color: AppColors.brandPrimary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentCustomer.name, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                              if (currentCustomer.phone != null)
                                Text(
                                  currentCustomer.phone!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildBalanceBadge(currentCustomer.balance),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(PhosphorIconsRegular.x, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tabs Switcher (3 Tabs)
                  Row(
                    children: [
                      _buildTabButton(
                        label: 'Чеки & Заказы',
                        icon: PhosphorIconsRegular.receipt,
                        isActive: _activeTab == 0,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        label: 'Взаиморасчеты (Сальдо)',
                        icon: PhosphorIconsRegular.wallet,
                        isActive: _activeTab == 1,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        label: 'Бонусы & LTV',
                        icon: PhosphorIconsRegular.gift,
                        isActive: _activeTab == 2,
                        onTap: () => setState(() => _activeTab = 2),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onEdit,
                        icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                        tooltip: 'Редактировать клиента',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Tab Content
                  Expanded(
                    child: _buildActiveTabContent(context, currentCustomer, transactions, isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    Customer currentCustomer,
    List<CustomerTransaction> transactions,
    bool isDark,
  ) {
    switch (_activeTab) {
      case 0:
        return CustomerOrdersTab(customer: currentCustomer);
      case 1:
        return _buildLedgerTab(context, currentCustomer, transactions, isDark);
      case 2:
      default:
        return CustomerBonusTab(customer: currentCustomer);
    }
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandPrimary.withValues(alpha: 0.15) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: isActive ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerTab(
    BuildContext context,
    Customer currentCustomer,
    List<CustomerTransaction> transactions,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _openPaymentModal(context, currentCustomer),
              icon: const Icon(PhosphorIconsRegular.money, size: 18),
              label: Text(currentCustomer.balance < 0 ? 'Принять оплату долга' : 'Внести депозит'),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentCustomer.balance < 0 ? AppColors.brandPrimary : AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => CustomerStatementPdfService.downloadStatement(currentCustomer, transactions, 'с'),
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
                            '${isDebit ? '-' : '+'} ${txn.amount.toStringAsFixed(2)} с',
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

  Widget _buildBalanceBadge(double balance) {
    Color bg;
    Color fg;
    String text;

    if (balance < -0.01) {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
      text = 'Долг: ${balance.abs().toStringAsFixed(2)} с';
    } else if (balance > 0.01) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      text = 'Депозит: +${balance.toStringAsFixed(2)} с';
    } else {
      bg = Colors.grey.withValues(alpha: 0.12);
      fg = Colors.grey;
      text = '0.00 с';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
