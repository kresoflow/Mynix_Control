// ==============================================================================
// МОДУЛЬ: POS / Мобильная раскладка кассы (PosMobileLayout)
// ДОМЕН: lib/features/pos/view/widgets/pos_mobile_layout.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Адаптивная мобильная раскладка POS:
// 1. Отображает сетку меню на весь экран.
// 2. Плавающая кнопка корзины (Glassmorphism FAB) с бейджем количества и суммой.
// 3. Открывает корзину PosCart в модальной шторке снизу.
//
// ==============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:kreso_frontend/features/pos/view/widgets/pos_cart.dart';
import 'package:kreso_frontend/features/pos/view/widgets/pos_menu_grid.dart';

// ── 1. Мобильная раскладка POS ────────────────────────────────────────────────

class PosMobileLayout extends StatelessWidget {
  const PosMobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const PosMenuGrid(),
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
                  borderRadius: AppRadii.cardRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.transparent,
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
                                boxShadow: AppShadows.dialog,
                              ),
                              child: const ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                                child: PosCart(),
                              ),
                            ),
                          ),
                        );
                      },
                      borderRadius: AppRadii.cardRadius,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.92),
                          borderRadius: AppRadii.cardRadius,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.25),
                                borderRadius: AppRadii.cardRadius,
                              ),
                              child: Text(
                                '$itemCount',
                                style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text('Корзина', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
                            Text(
                              state.total.toCurrency(context),
                              style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
