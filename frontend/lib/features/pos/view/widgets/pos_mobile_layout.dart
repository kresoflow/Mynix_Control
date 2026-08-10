import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_menu_grid.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_cart.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'dart:ui';

class PosMobileLayout extends StatelessWidget {
  const PosMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: PosMenuGrid(),
        ),
        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final itemCount = state.items.fold(0, (sum, item) => sum + item.quantity);
            if (itemCount == 0) return const SizedBox.shrink();

            return Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => BlocListener<CartBloc, CartState>(
                            listenWhen: (previous, current) => !previous.submitSuccess && current.submitSuccess,
                            listener: (context, state) {
                              if (state.submitSuccess) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.85,
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 40,
                                    offset: const Offset(0, -10),
                                  )
                                ],
                              ),
                              child: const ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                                child: PosCart(),
                              ),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0, // Glassmorphism relies on blur, not hard shadows
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$itemCount',
                              style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('Корзина', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text(
                            state.total.toCurrency(context),
                            style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
