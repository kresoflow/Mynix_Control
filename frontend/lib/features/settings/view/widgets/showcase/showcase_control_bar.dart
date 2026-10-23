// ==============================================================================
// МОДУЛЬ: Настройки / Витрина UI Kit / Интерактивный пульт переключения тем
// ДОМЕН: lib/features/settings/view/widgets/showcase/showcase_control_bar.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/theme_bloc.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

/// Интерактивная панель управления для тестирования дизайн-системы Kreso Flow.
/// 
/// Позволяет в реальном времени переключать все 6 комбинаций тем (Dark/Light × 3 палитры),
/// а также включать мгновенный сенсорный режим (Instant Touch / POS Mode).
class ShowcaseControlBar extends StatefulWidget {
  final VoidCallback? onMotionChanged;

  const ShowcaseControlBar({super.key, this.onMotionChanged});

  @override
  State<ShowcaseControlBar> createState() => _ShowcaseControlBarState();
}

class _ShowcaseControlBarState extends State<ShowcaseControlBar> {
  bool _instantTouch = AppMotion.disableAnimations;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final isDark = state.isDark(context);
        final currentPalette = state.palette;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Заголовок и текущий статус ──────────────────────────────
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: AppRadii.inputRadius,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.paintBrushBroad,
                      color: AppColors.brandPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тестовая матрица дизайн-системы (Approval Gate)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        Text(
                          'Проверьте любой компонент во всех 6 темах и режиме сенсорного терминала (POS)',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppStatusBadge(
                    label: _buildActiveLabel(isDark, currentPalette),
                    variant: AppBadgeVariant.brand,
                    hasDot: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── Элементы управления ────────────────────────────────────
              Wrap(
                spacing: 20,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // 1. Режим: Светлая / Темная
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'РЕЖИМ (СВЕТ / ТЕНЬ)',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppSegmentedControl<ThemeMode>(
                        selectedValue: isDark ? ThemeMode.dark : ThemeMode.light,
                        size: AppSegmentedSize.sm,
                        onValueChanged: (mode) {
                          context.read<ThemeBloc>().add(SetThemeMode(mode));
                        },
                        items: const [
                          AppSegmentedItem(
                            value: ThemeMode.light,
                            label: 'Светлая',
                            icon: PhosphorIconsRegular.sun,
                          ),
                          AppSegmentedItem(
                            value: ThemeMode.dark,
                            label: 'Тёмная',
                            icon: PhosphorIconsRegular.moon,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 2. Палитра: Ocean / Cream / Ember
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ПАЛИТРА ЦВЕТОВ',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppSegmentedControl<ThemePalette>(
                        selectedValue: currentPalette,
                        size: AppSegmentedSize.sm,
                        onValueChanged: (pal) {
                          context.read<ThemeBloc>().add(SetThemePalette(pal));
                        },
                        items: const [
                          AppSegmentedItem(
                            value: ThemePalette.ocean,
                            label: 'Ocean (Синий)',
                            icon: PhosphorIconsRegular.drop,
                          ),
                          AppSegmentedItem(
                            value: ThemePalette.cream,
                            label: 'Cream (Кофе)',
                            icon: PhosphorIconsRegular.coffee,
                          ),
                          AppSegmentedItem(
                            value: ThemePalette.ember,
                            label: 'Ember (Янтарь)',
                            icon: PhosphorIconsRegular.fire,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 3. Режим анимаций: Fluid / Instant Touch
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'АНИМАЦИИ (MOTION)',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppSegmentedControl<bool>(
                        selectedValue: _instantTouch,
                        size: AppSegmentedSize.sm,
                        onValueChanged: (val) {
                          setState(() {
                            _instantTouch = val;
                            AppMotion.disableAnimations = val;
                          });
                          widget.onMotionChanged?.call();
                          AppToast.showInfo(
                            context,
                            val
                                ? 'Сенсорный POS-режим: анимации отключены (отклик 0 мс)'
                                : 'Режим Fluid UI: анимации включены',
                          );
                        },
                        items: const [
                          AppSegmentedItem(
                            value: false,
                            label: 'Fluid UI',
                            icon: PhosphorIconsRegular.lightning,
                          ),
                          AppSegmentedItem(
                            value: true,
                            label: 'Instant Touch (POS)',
                            icon: PhosphorIconsRegular.handTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildActiveLabel(bool isDark, ThemePalette palette) {
    final modeStr = isDark ? 'Dark' : 'Light';
    final palStr = switch (palette) {
      ThemePalette.ocean => 'Ocean',
      ThemePalette.cream => 'Cream',
      ThemePalette.ember => 'Ember',
    };
    final motionStr = _instantTouch ? '⚡ Instant POS' : 'Fluid';
    return '$palStr ($modeStr) • $motionStr';
  }
}
