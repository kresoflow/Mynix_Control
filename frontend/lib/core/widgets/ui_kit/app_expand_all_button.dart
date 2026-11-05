// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Кнопка «Развернуть / Свернуть всё»
// ДОМЕН: lib/core/widgets/ui_kit/app_expand_all_button.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Единый стандарт раскрытия/схлопывания аккордеонов и деревьев:
// 1. Компактный вид (compact): квадрат 34x34 с шевроном caretDown/Up и Tooltip.
// 2. Длинный вид (full): плашка с шевроном и текстом «Развернуть все» / «Свернуть все».
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Режим отображения кнопки управления раскрытием
enum AppExpandAllMode {
  /// Компактная квадратная кнопка с подсказкой (для узких сайдбаров и тулбаров)
  compact,

  /// Полноразмерная кнопка с шевроном и текстовой меткой (для таблиц и модалок)
  full,
}

/// [UI-KIT] Системная кнопка сворачивания/разворачивания групп, категорий и списков.
class AppExpandAllButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppExpandAllMode mode;
  final String expandText;
  final String collapseText;

  const AppExpandAllButton({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    this.mode = AppExpandAllMode.full,
    this.expandText = 'Развернуть все',
    this.collapseText = 'Свернуть все',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLabel = isExpanded ? collapseText : expandText;
    final iconData = isExpanded ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown;

    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final iconColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    if (mode == AppExpandAllMode.compact) {
      return Tooltip(
        message: currentLabel,
        child: InkWell(
          onTap: onToggle,
          borderRadius: AppRadii.inputRadius,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadii.inputRadius,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              iconData,
              size: 16,
              color: textColor,
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onToggle,
      borderRadius: AppRadii.inputRadius,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadii.inputRadius,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 14,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              currentLabel,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
