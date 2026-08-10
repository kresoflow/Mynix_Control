import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../bloc/orders_bloc.dart';
import 'widgets/order_card.dart';
import 'widgets/orders_skeleton.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Заказы', style: AppTextStyles.h1),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
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
                  return const OrdersSkeleton(count: 6);
                } else if (state is OrdersError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: AppTextStyles.body.copyWith(color: AppColors.danger),
                    ),
                  );
                } else if (state is OrdersLoaded) {
                  if (state.orders.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет заказов',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkSubtext),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                    itemCount: state.orders.length,
                    itemBuilder: (context, index) {
                      return OrderCard(order: state.orders[index]);
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
}
