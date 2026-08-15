import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_event.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_state.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'widgets/kds_header.dart';
import 'widgets/kds_order_card.dart';

class KdsBoard extends StatefulWidget {
  const KdsBoard({super.key});

  @override
  State<KdsBoard> createState() => _KdsBoardState();
}

class _KdsBoardState extends State<KdsBoard> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<KitchenBloc>().add(ConnectKitchen(authState.tenantId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<KitchenBloc, KitchenState>(
      builder: (context, state) {
        int activeCount = 0;
        List<Map<String, dynamic>> orders = [];
        bool isConnected = false;

        if (state is KitchenLoaded) {
          activeCount = state.orders.length;
          orders = state.orders;
          isConnected = state.isConnected;
        }

        return Container(
          color: isDark ? AppColors.darkBg : AppColors.lightBg,
          child: Column(
            children: [
              KdsHeader(
                activeCount: activeCount,
                isConnected: isConnected,
                isDark: isDark,
              ),
              if (state is KitchenLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (orders.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      "Нет активных заказов",
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return KdsOrderCard(order: order, isDark: isDark);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
