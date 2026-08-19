import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/models/bonus_transaction.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_bloc.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_event.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_state.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/bonus_adjustment_modal.dart';

class CustomerBonusTab extends StatefulWidget {
  final Customer customer;

  const CustomerBonusTab({super.key, required this.customer});

  @override
  State<CustomerBonusTab> createState() => _CustomerBonusTabState();
}

class _CustomerBonusTabState extends State<CustomerBonusTab> {
  @override
  void initState() {
    super.initState();
    context.read<CrmBloc>().add(LoadCustomerBonusTransactionsEvent(widget.customer.id));
  }

  void _openBonusModal(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (_) => BonusAdjustmentModal(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocBuilder<CrmBloc, CrmState>(
      builder: (context, state) {
        Customer currentCustomer = widget.customer;
        List<BonusTransaction> txns = [];

        if (state is CrmLoaded) {
          final found = state.customers.where((c) => c.id == widget.customer.id);
          if (found.isNotEmpty) currentCustomer = found.first;
          txns = state.bonusTransactionsCache[widget.customer.id] ?? [];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LTV & Loyalty Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'LTV (Выручка)',
                    value: '${currentCustomer.totalSpent.toStringAsFixed(0)} с',
                    icon: PhosphorIconsRegular.chartLineUp,
                    color: AppColors.brandPrimary,
                    cardBg: cardBg,
                    border: border,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Заказов / Ср. чек',
                    value: '${currentCustomer.ordersCount} / ${currentCustomer.averageCheck.toStringAsFixed(0)} с',
                    icon: PhosphorIconsRegular.receipt,
                    color: Colors.blueAccent,
                    cardBg: cardBg,
                    border: border,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Уровень лояльности',
                    value: currentCustomer.tierName,
                    icon: PhosphorIconsRegular.crown,
                    color: currentCustomer.tierLevel == 'gold'
                        ? Colors.amber
                        : (currentCustomer.tierLevel == 'silver' ? Colors.blueGrey : Colors.orangeAccent),
                    cardBg: cardBg,
                    border: border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bonus Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.gift, size: 18, color: AppColors.brandPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Бонусный баланс: ${currentCustomer.bonusBalance.toStringAsFixed(0)} бонусов',
                      style: AppTextStyles.h3.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openBonusModal(context, currentCustomer),
                  icon: const Icon(PhosphorIconsRegular.plusMinus, size: 16),
                  label: const Text('Начислить / списать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Transactions Table
            Expanded(
              child: txns.isEmpty
                  ? Center(
                      child: Text(
                        'История бонусов пуста',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: border.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        final t = txns[index];
                        final isCredit = t.isCredit;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCredit ? PhosphorIconsRegular.arrowCircleDownRight : PhosphorIconsRegular.arrowCircleUpRight,
                                size: 18,
                                color: isCredit ? AppColors.success : AppColors.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.typeLabel,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    if (t.comment != null)
                                      Text(
                                        t.comment!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                DateFormat('dd.MM.yyyy HH:mm').format(t.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${isCredit ? '+' : '-'}${t.amount.toStringAsFixed(0)} бонусов',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isCredit ? AppColors.success : AppColors.error,
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
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
