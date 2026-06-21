import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/features/pos/bloc/cart_bloc.dart';

class PosCartHeader extends StatelessWidget {
  const PosCartHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(width: 10),
          Text('Текущий заказ', style: AppTextStyles.h3),
          const Spacer(),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${state.items.length} поз.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Clear cart button
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                color: AppColors.darkSubtext,
                tooltip: 'Очистить заказ',
                onPressed: () => context.read<CartBloc>().add(ClearCart()),
              );
            },
          ),
        ],
      ),
    );
  }
}
