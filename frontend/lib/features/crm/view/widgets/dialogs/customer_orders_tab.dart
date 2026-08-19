import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_bloc.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_event.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_state.dart';

class CustomerOrdersTab extends StatefulWidget {
  final Customer customer;

  const CustomerOrdersTab({super.key, required this.customer});

  @override
  State<CustomerOrdersTab> createState() => _CustomerOrdersTabState();
}

class _CustomerOrdersTabState extends State<CustomerOrdersTab> {
  @override
  void initState() {
    super.initState();
    context.read<CrmBloc>().add(LoadCustomerOrdersEvent(widget.customer.id));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocBuilder<CrmBloc, CrmState>(
      builder: (context, state) {
        List<Map<String, dynamic>> orders = [];

        if (state is CrmLoaded) {
          orders = state.ordersCache[widget.customer.id] ?? [];
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.receipt,
                  size: 40,
                  color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10),
                Text(
                  'История заказов пуста',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderNumber = order['order_number'] ?? order['id'];
            final total = (order['total'] as num?)?.toDouble() ?? 0.0;
            final bonusSpent = (order['bonus_spent'] as num?)?.toDouble() ?? 0.0;
            final paymentMethod = (order['payment_method'] ?? 'cash').toString();
            final createdAtStr = (order['created_at'] ?? '').toString();
            final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

            DateTime? dt;
            try {
              dt = DateTime.parse(createdAtStr);
            } catch (_) {}

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Чек #$orderNumber',
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (dt != null)
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(dt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildPaymentBadge(paymentMethod),
                          const SizedBox(width: 8),
                          Text(
                            '${total.toStringAsFixed(0)} с',
                            style: AppTextStyles.h3.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (bonusSpent > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(PhosphorIconsRegular.gift, size: 12, color: AppColors.brandPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Списано бонусов: ${bonusSpent.toStringAsFixed(0)} бонусов',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Dish items list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((it) {
                      final name = it['menu_item_name'] ?? 'Позиция';
                      final qty = it['quantity'] ?? 1;
                      final subtotal = (it['subtotal'] as num?)?.toDouble() ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$qty × $name',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            Text(
                              '${subtotal.toStringAsFixed(0)} с',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentBadge(String method) {
    String label;
    Color color;

    switch (method.toLowerCase()) {
      case 'debt':
        label = 'В долг';
        color = AppColors.error;
        break;
      case 'deposit':
        label = 'Депозит';
        color = Colors.blueAccent;
        break;
      case 'transfer':
        label = 'Перевод';
        color = Colors.purpleAccent;
        break;
      case 'card':
        label = 'Карта';
        color = Colors.indigoAccent;
        break;
      case 'cash':
      default:
        label = 'Наличные';
        color = AppColors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}
