import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui';

class PosSettingsModal extends StatelessWidget {
  const PosSettingsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PosSettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(PhosphorIconsRegular.slidersHorizontal, color: AppColors.brandPrimary),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Настройки кассы',
                    style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 32),
              BlocBuilder<PosSettingsCubit, PosSettingsState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card Size Slider ──
                      Text(
                        'Размер карточек',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(PhosphorIconsRegular.squaresFour, size: 20, color: AppColors.darkSubtext),
                          Expanded(
                            child: Slider(
                              value: state.cardSize,
                              min: 150.0,
                              max: 300.0,
                              divisions: 15,
                              label: state.cardSize.round().toString(),
                              activeColor: AppColors.brandPrimary,
                              onChanged: (val) {
                                context.read<PosSettingsCubit>().updateCardSize(val);
                              },
                            ),
                          ),
                          Icon(PhosphorIconsRegular.squaresFour, size: 32, color: AppColors.darkSubtext),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Cart Width Slider ──
                      Text(
                        'Ширина корзины',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(PhosphorIconsRegular.shoppingCart, size: 20, color: AppColors.darkSubtext),
                          Expanded(
                            child: Slider(
                              value: state.cartWidthPercentage.toDouble(),
                              min: 20.0,
                              max: 50.0,
                              divisions: 6,
                              label: '${state.cartWidthPercentage}%',
                              activeColor: AppColors.brandPrimary,
                              onChanged: (val) {
                                context.read<PosSettingsCubit>().updateCartWidth(val.toInt());
                              },
                            ),
                          ),
                          Icon(PhosphorIconsRegular.shoppingCart, size: 32, color: AppColors.darkSubtext),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Rainbow Colors Switch ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Разноцветные категории',
                              style: AppTextStyles.h3,
                            ),
                            Switch(
                              value: state.enableRainbowColors,
                              activeThumbColor: AppColors.brandPrimary,
                              onChanged: (val) {
                                context.read<PosSettingsCubit>().toggleRainbowColors();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
