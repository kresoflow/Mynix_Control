
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../bloc/orders_bloc.dart';
import 'widgets/order_details_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(LoadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Заказы', style: AppTextStyles.h1),
                IconButton(
                  icon: Icon(PhosphorIconsRegular.arrowsClockwise),
                  onPressed: () => context.read<OrdersBloc>().add(LoadOrders()),
                  tooltip: 'Обновить',
                )
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is OrdersError) {
                  return Center(child: Text(state.message, style: AppTextStyles.body.copyWith(color: AppColors.danger)));
                } else if (state is OrdersLoaded) {
                  if (state.orders.isEmpty) {
                    return Center(child: Text('Нет заказов', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkSubtext)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: state.orders.length,
                    itemBuilder: (context, index) {
                      final order = state.orders[index];
                      final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
                      final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => BlocProvider.value(
                                value: context.read<OrdersBloc>(),
                                child: OrderDetailsDialog(order: order),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('#${order.orderNumber}', style: AppTextStyles.body.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
                                      const SizedBox(height: 4),
                                      Text('${order.items.length} позиций', style: AppTextStyles.body),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(order.status),
                                const SizedBox(width: 24),
                                Text(order.total.toCurrency(context), style: AppTextStyles.h3),
                                const SizedBox(width: 16),
                                Icon(PhosphorIconsRegular.caretRight, color: AppColors.darkSubtext),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'new': color = AppColors.brandPrimary; label = 'Новый'; break;
      case 'cooking': color = AppColors.warning; label = 'Готовится'; break;
      case 'ready': color = AppColors.success; label = 'Готов'; break;
      case 'completed': color = AppColors.darkSubtext; label = 'Завершен'; break;
      case 'cancelled': color = AppColors.danger; label = 'Отменен'; break;
      default: color = AppColors.darkText; label = status; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
