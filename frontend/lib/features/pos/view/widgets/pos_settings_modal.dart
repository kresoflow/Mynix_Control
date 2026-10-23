// ==============================================================================
// МОДУЛЬ: POS / Настройки терминала кассы (PosSettingsModal)
// ДОМЕН: lib/features/pos/view/widgets/pos_settings_modal.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Модальная панель операционных настроек POS:
// 1. Настройка сетки каталога меню (3–6 колонок).
// 2. Настройка адаптивной ширины корзины заказа (20%–50%).
// 3. Тумблер цветных категорий через компонент AppSwitch.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_switch.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_settings_cubit.dart';

// ── 1. Нижняя модальная шторка настроек POS ──────────────────────────────────

class PosSettingsModal extends StatelessWidget {
  const PosSettingsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => const PosSettingsModal(),
    );
  }

  String _getCardSizeLabel(int columns) {
    switch (columns) {
      case 3:
        return 'Крупный (3)';
      case 4:
        return 'Стандарт (4)';
      case 5:
        return 'Средний (5)';
      case 6:
        return 'Компактный (6)';
      default:
        return '$columns кол.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: AppShadows.dialog,
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
                    borderRadius: AppRadii.cardRadius,
                  ),
                  child: const Icon(PhosphorIconsRegular.slidersHorizontal, color: AppColors.brandPrimary),
                ),
                AppSpacing.hMd,
                Text(
                  'Настройки кассы',
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            BlocBuilder<PosSettingsCubit, PosSettingsState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Размер карточек / Колонок ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Размер карточек', style: AppTextStyles.h3),
                        Text(
                          _getCardSizeLabel(state.columnsCount),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSm,
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.squaresFour, size: 16, color: AppColors.darkSubtext),
                        Expanded(
                          child: Slider(
                            value: (9 - state.columnsCount).clamp(3, 6).toDouble(),
                            min: 3.0,
                            max: 6.0,
                            divisions: 3,
                            label: _getCardSizeLabel(state.columnsCount),
                            activeColor: AppColors.brandPrimary,
                            onChanged: (val) {
                              context.read<PosSettingsCubit>().updateColumnsCount(9 - val.round());
                            },
                          ),
                        ),
                        const Icon(PhosphorIconsRegular.squaresFour, size: 28, color: AppColors.darkSubtext),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Ширина корзины ──
                    Text('Ширина корзины', style: AppTextStyles.h3),
                    AppSpacing.vSm,
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.shoppingCart, size: 20, color: AppColors.darkSubtext),
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
                        const Icon(PhosphorIconsRegular.shoppingCart, size: 32, color: AppColors.darkSubtext),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Тумблер цветных категорий ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.05)
                            : AppColors.pureBlack.withValues(alpha: 0.05),
                        borderRadius: AppRadii.cardRadius,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Цветные категории', style: AppTextStyles.h3),
                                const SizedBox(height: 2),
                                Text(
                                  'Использовать цвета категорий из каталога',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.hSm,
                          AppSwitch(
                            value: state.enableRainbowColors,
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
    );
  }
}
