// ==============================================================================
// МОДУЛЬ: Настройки / Витрина UI Kit / Лаборатория анимаций и движения
// ДОМЕН: lib/features/settings/view/widgets/showcase/showcase_motion_section.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

/// Интерактивная лаборатория для изолированного тестирования анимаций и ховеров.
class ShowcaseMotionSection extends StatefulWidget {
  final bool isDark;

  const ShowcaseMotionSection({super.key, required this.isDark});

  @override
  State<ShowcaseMotionSection> createState() => _ShowcaseMotionSectionState();
}

class _ShowcaseMotionSectionState extends State<ShowcaseMotionSection> {
  bool _isExpanded = false;
  int _selectedTimingIndex = 1; // 0 = Fast, 1 = Standard, 2 = Modal, 3 = Instant
  bool _hoverElevation = false;
  bool _hoverGlow = false;

  Duration get _activeDuration => switch (_selectedTimingIndex) {
        0 => AppMotion.fast,
        1 => AppMotion.standard,
        2 => AppMotion.modal,
        _ => Duration.zero,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Шапка секции ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '8. Лаборатория анимаций (AppMotion & Hover Playground)',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Изолированное тестирование кривых плавности, скоростей и интерактивных ховеров.',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: _isExpanded ? 'Свернуть тест' : 'Запустить тест (Trigger)',
                icon: PhosphorIconsRegular.play,
                size: AppButtonSize.sm,
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 1. Селектор таймингов ─────────────────────────────────────────
          Row(
            children: [
              Text(
                'Скорость перехода: ',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(width: 8),
              AppSegmentedControl<int>(
                selectedValue: _selectedTimingIndex,
                size: AppSegmentedSize.sm,
                onValueChanged: (val) => setState(() => _selectedTimingIndex = val),
                items: const [
                  AppSegmentedItem(value: 0, label: 'Fast (100ms)'),
                  AppSegmentedItem(value: 1, label: 'Standard (180ms)'),
                  AppSegmentedItem(value: 2, label: 'Modal (250ms)'),
                  AppSegmentedItem(value: 3, label: 'Instant Touch (0ms)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 2. Сравнение 4 кривых движения ──────────────────────────────
          Text(
            'Сравнение кривых движения (Curves Matrix):',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final cards = [
                _buildCurveTester(
                  title: 'standardCurve',
                  subtitle: 'easeOutCubic (Stripe)',
                  curve: AppMotion.standardCurve,
                  color: AppColors.brandPrimary,
                  isDark: isDark,
                ),
                _buildCurveTester(
                  title: 'bounceCurve',
                  subtitle: 'easeOutBack (Пружина)',
                  curve: AppMotion.bounceCurve,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                _buildCurveTester(
                  title: 'enterCurve',
                  subtitle: 'decelerate (Акцент)',
                  curve: AppMotion.enterCurve,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                _buildCurveTester(
                  title: 'exitCurve',
                  subtitle: 'easeInCubic (Затухание)',
                  curve: AppMotion.exitCurve,
                  color: AppColors.danger,
                  isDark: isDark,
                ),
              ];

              if (isNarrow) {
                return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList());
              }
              return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList());
            },
          ),
          const SizedBox(height: 24),

          // ── 3. Интерактивная витрина микро-ховеров ───────────────────────
          Text(
            'Интерактивные эффекты наведения мыши (Hover & Micro-interactions):',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Вариант 1: Мягкий подъем (Elevation + Scale 1.03)
              MouseRegion(
                onEnter: (_) => setState(() => _hoverElevation = true),
                onExit: (_) => setState(() => _hoverElevation = false),
                child: AnimatedScale(
                  scale: _hoverElevation ? 1.03 : 1.0,
                  duration: AppMotion.fast,
                  curve: AppMotion.standardCurve,
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standardCurve,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: AppRadii.inputRadius,
                      boxShadow: _hoverElevation ? AppShadows.buttonGlow(AppColors.brandPrimary) : AppShadows.light,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.arrowUpRight, color: AppColors.pureWhite, size: 16),
                        SizedBox(width: 8),
                        Text('Hover 1: Мягкий подъем (Elevation)', style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),

              // Вариант 2: Неоновое свечение (Luminous Brand Glow)
              MouseRegion(
                onEnter: (_) => setState(() => _hoverGlow = true),
                onExit: (_) => setState(() => _hoverGlow = false),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standardCurve,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    borderRadius: AppRadii.inputRadius,
                    border: Border.all(
                      color: _hoverGlow ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: _hoverGlow ? 1.5 : 1.0,
                    ),
                    boxShadow: _hoverGlow
                        ? AppShadows.glow(AppColors.brandPrimary, opacity: isDark ? 0.40 : 0.25, blur: 14, spread: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.sparkle, color: _hoverGlow ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Hover 2: Неоновое свечение (Glow)',
                        style: TextStyle(
                          color: _hoverGlow ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurveTester({
    required String title,
    required String subtitle,
    required Curve curve,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBg,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(height: 12),
          AnimatedAlign(
            alignment: _isExpanded ? Alignment.centerRight : Alignment.centerLeft,
            duration: _activeDuration,
            curve: curve,
            child: AnimatedContainer(
              duration: _activeDuration,
              curve: curve,
              width: _isExpanded ? 32 : 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: _isExpanded ? AppRadii.buttonRadius : AppRadii.badgeRadius,
                boxShadow: AppShadows.dotGlow(color, opacity: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
