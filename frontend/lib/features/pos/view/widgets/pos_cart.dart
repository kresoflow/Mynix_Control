import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/features/pos/bloc/cart_bloc.dart';

import 'components/pos_cart_header.dart';
import 'components/pos_cart_item_tile.dart';
import 'components/pos_empty_cart.dart';
import 'components/pos_checkout_panel.dart';

class PosCart extends StatelessWidget {
  const PosCart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          const PosCartHeader(),

          // ── Items ──────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state.items.isEmpty) {
                  return const PosEmptyCart();
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: state.items.length,
                  separatorBuilder: (ctx, idx) => Divider(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return PosCartItemTile(cartItem: item);
                  },
                );
              },
            ),
          ),

          // ── Checkout ───────────────────────────────────────────────────────
          const PosCheckoutPanel(),
        ],
      ),
    );
  }
}
