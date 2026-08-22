import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:mynix_frontend/features/orders/repository/orders_repository.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/orders/view/widgets/order_card.dart';

class OrderHistoryTab extends StatefulWidget {
  final String period;
  final DateTime? startDate;
  final DateTime? endDate;

  const OrderHistoryTab({
    super.key,
    required this.period,
    this.startDate,
    this.endDate,
  });

  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab> {
  late final OrdersBloc _ordersBloc;

  @override
  void initState() {
    super.initState();
    _ordersBloc = OrdersBloc(repository: OrdersRepository(dio: apiClient.dio));
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant OrderHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    String? startStr;
    String? endStr;

    final now = DateTime.now();

    if (widget.period == 'custom' && widget.startDate != null && widget.endDate != null) {
      startStr = DateFormat('yyyy-MM-dd').format(widget.startDate!);
      endStr = DateFormat('yyyy-MM-dd').format(widget.endDate!);
    } else {
      DateTime start = now;
      final DateTime end = now;

      switch (widget.period) {
        case 'week':
          start = now.subtract(const Duration(days: 6));
          break;
        case 'month':
          start = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          start = DateTime(now.year, 1, 1);
          break;
        case 'today':
        default:
          start = now;
          break;
      }

      startStr = DateFormat('yyyy-MM-dd').format(start);
      endStr = DateFormat('yyyy-MM-dd').format(end);
    }

    _ordersBloc.add(LoadOrders(startDate: startStr, endDate: endStr));
  }

  @override
  void dispose() {
    _ordersBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _ordersBloc,
      child: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading || state is OrdersInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrdersError) {
            return Center(
              child: Text(
                state.message,
                style: AppTextStyles.body.copyWith(color: AppColors.danger),
              ),
            );
          }

          if (state is OrdersLoaded) {
            final orders = state.orders;

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.receipt, size: 64, color: isDark ? Colors.white24 : Colors.black38),
                    const SizedBox(height: 16),
                    Text(
                      'Нет заказов за этот период',
                      style: AppTextStyles.h3.copyWith(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadOrders();
              },
              color: AppColors.brandPrimary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return OrderCard(order: orders[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
