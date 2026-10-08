// ==============================================================================
// УНИФИЦИРОВАННЫЙ ЧЕКБОКС (APP CHECKBOX & CHECKBOX TILE)
// ==============================================================================
//
// [ИНВАРИАНТ] Запрет сырых Material Checkbox с разнородными стилями.
// Поддержка 6 тем Kreso Flow, скруглений 6px, тактильных анимаций и POS-режима.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Стандартизированные размеры чекбокса
enum AppCheckboxSize {
  /// Компактный размер для плотных таблиц и спецификаций (18x18)
  sm(18.0, 12.0, 5.0),

  /// Стандартный размер для форм, списков и настроек (22x22)
  md(22.0, 14.0, 6.0);

  final double boxSize;
  final double iconSize;
  final double borderRadius;

  const AppCheckboxSize(this.boxSize, this.iconSize, this.borderRadius);
}

/// [UI-KIT] Брендовый чекбокс Kreso Flow с плавной анимацией и поддержкой меток
class AppCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isIndeterminate;
  final AppCheckboxSize size;
  final String? label;
  final String? subtitle;
  final bool disabled;
  final Color? customColor;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.isIndeterminate = false,
    this.size = AppCheckboxSize.md,
    this.label,
    this.subtitle,
    this.disabled = false,
    this.customColor,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  bool _isHovered = false;

  void _handleTap() {
    if (widget.disabled || widget.onChanged == null) return;
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMotionDisabled = AppMotion.disableAnimations;
    final primary = widget.customColor ?? AppColors.brandPrimary;
    final enabled = !widget.disabled && widget.onChanged != null;

    final isActive = widget.value || widget.isIndeterminate;
    final effectiveHover = enabled && !isMotionDisabled && _isHovered;

    // ── Цвета фона и границ ──
    final Color bg;
    final Color borderColor;

    if (!enabled) {
      bg = isActive
          ? primary.withValues(alpha: 0.35)
          : (isDark ? AppColors.darkCard : AppColors.lightCard);
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    } else if (isActive) {
      bg = primary;
      borderColor = primary;
    } else {
      bg = effectiveHover
          ? primary.withValues(alpha: 0.08)
          : (isDark ? AppColors.darkCard : AppColors.lightSurface);
      borderColor = effectiveHover
          ? primary.withValues(alpha: 0.7)
          : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    }

    final boxWidget = AnimatedContainer(
      duration: isMotionDisabled ? Duration.zero : AppMotion.fastDuration,
      curve: AppMotion.standardCurve,
      width: widget.size.boxSize,
      height: widget.size.boxSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.size.borderRadius),
        border: Border.all(
          color: borderColor,
          width: isActive ? 1.5 : 1.2,
        ),
        boxShadow: effectiveHover && isActive && !isMotionDisabled
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: isMotionDisabled ? Duration.zero : AppMotion.fastDuration,
          transitionBuilder: (child, anim) => isMotionDisabled
              ? child
              : ScaleTransition(scale: anim, child: child),
          child: widget.isIndeterminate
              ? Icon(
                  PhosphorIconsBold.minus,
                  key: const ValueKey('minus'),
                  size: widget.size.iconSize,
                  color: Colors.white,
                )
              : widget.value
                  ? Icon(
                      PhosphorIconsBold.check,
                      key: const ValueKey('check'),
                      size: widget.size.iconSize,
                      color: Colors.white,
                    )
                  : const SizedBox.shrink(),
        ),
      ),
    );

    // ── Если чекбокс одиночный без подписи ──
    if (widget.label == null) {
      return MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: boxWidget,
        ),
      );
    }

    // ── Чекбокс со строкой подписи (полнострочный клик) ──
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.subtitle != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: widget.subtitle != null ? 2.0 : 0.0,
              ),
              child: boxWidget,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: enabled
                          ? (isDark ? AppColors.darkText : AppColors.lightText)
                          : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
