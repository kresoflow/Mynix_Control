import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// Интенсивность микро-анимации наведения (Hover Effect)
enum AppHoverStyle {
  /// Без увеличения и теней (scale: 1.0) — для плотных таблиц, строк и тулбаров
  none(1.0, false),

  /// Микро-увеличение на 1% (scale: 1.01, по умолчанию) — стандарт для кнопок форм
  subtle(1.01, false),

  /// Ощутимый подъем (scale: 1.03 + Ambient Glow) — для главных CTA-кнопок
  lift(1.03, true),

  /// Без скейла (1.0), но с контурным свечением бренда
  glow(1.0, true);

  final double scale;
  final bool hasGlow;

  const AppHoverStyle(this.scale, this.hasGlow);
}

enum AppButtonSize {
  xs(28.0, 14.0, 11.0, 8.0, 6.0),
  sm(32.0, 16.0, 12.0, 12.0, 8.0),
  md(36.0, 16.0, 13.0, 14.0, 8.0),
  lg(44.0, 18.0, 14.0, 20.0, 10.0),
  xl(52.0, 22.0, 16.0, 24.0, 12.0);

  final double height;
  final double iconSize;
  final double fontSize;
  final double horizontalPadding;
  final double borderRadius;

  const AppButtonSize(
    this.height,
    this.iconSize,
    this.fontSize,
    this.horizontalPadding,
    this.borderRadius,
  );
}

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize? size;
  final double? height;
  final double? width;
  final bool isLoading;
  final bool isFullWidth;
  final bool isSelected;
  final String? tooltip;
  final Color? customColor;
  final double? borderRadius;
  final AppHoverStyle hoverStyle;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size,
    this.height,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isSelected = false,
    this.tooltip,
    this.customColor,
    this.borderRadius,
    this.hoverStyle = AppHoverStyle.subtle,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size,
    this.height,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isSelected = false,
    this.tooltip,
    this.customColor,
    this.borderRadius,
    this.hoverStyle = AppHoverStyle.subtle,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size,
    this.height,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isSelected = false,
    this.tooltip,
    this.customColor,
    this.borderRadius,
    this.hoverStyle = AppHoverStyle.subtle,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size,
    this.height,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isSelected = false,
    this.tooltip,
    this.customColor,
    this.borderRadius,
    this.hoverStyle = AppHoverStyle.subtle,
  }) : variant = AppButtonVariant.outline;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size,
    this.height,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isSelected = false,
    this.tooltip,
    this.customColor,
    this.borderRadius,
    this.hoverStyle = AppHoverStyle.subtle,
  }) : variant = AppButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size,
    this.height,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isSelected = false,
    this.tooltip,
    this.customColor,
    this.borderRadius,
    this.hoverStyle = AppHoverStyle.subtle,
  }) : variant = AppButtonVariant.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  int _lastTapTime = 0;

  void _handleTap() {
    if (widget.onPressed == null || widget.isLoading) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime < 400) return;
    _lastTapTime = now;
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadow;
    final effectiveSize = widget.size ?? AppButtonSize.lg;
    final double effectiveHeight = widget.height ?? effectiveSize.height;
    final double effectiveIconSize = effectiveSize.iconSize;
    final double effectiveFontSize = effectiveSize.fontSize;
    final bool isIconOnly = widget.label.isEmpty && widget.icon != null;
    final double effectiveHorizPadding = isIconOnly
        ? 0.0
        : (widget.width != null ? (effectiveSize.horizontalPadding * 0.7) : effectiveSize.horizontalPadding);
    final double? effectiveWidth = widget.isFullWidth
        ? double.infinity
        : (widget.width ?? (isIconOnly ? effectiveHeight : null));
    final double radius = widget.borderRadius ?? effectiveSize.borderRadius;

    final primary = widget.customColor ?? AppColors.brandPrimary;

    final isMotionDisabled = AppMotion.disableAnimations;
    final effectiveHovered = !isMotionDisabled && _isHovered;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = enabled ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
        fg = Colors.white;
        if (enabled && !isMotionDisabled) {
          shadow = AppShadows.buttonGlow(primary);
        }
        break;

      case AppButtonVariant.secondary:
        bg = widget.isSelected
            ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark
                ? (effectiveHovered ? AppColors.darkCardHover : AppColors.darkCard)
                : (effectiveHovered ? AppColors.lightBorder.withValues(alpha: 0.6) : AppColors.lightSurface));
        fg = widget.isSelected
            ? primary
            : (isDark ? AppColors.darkText : AppColors.lightText);
        border = Border.all(
          color: widget.isSelected
              ? primary.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        );
        break;

      case AppButtonVariant.outline:
        bg = widget.isSelected
            ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
            : (effectiveHovered ? primary.withValues(alpha: 0.08) : Colors.transparent);
        fg = widget.isSelected
            ? primary
            : (enabled ? primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
        border = Border.all(
          color: widget.isSelected
              ? primary
              : (enabled
                  ? (effectiveHovered ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder))
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        );
        break;

      case AppButtonVariant.danger:
        bg = enabled
            ? (effectiveHovered ? AppColors.danger : AppColors.danger.withValues(alpha: 0.12))
            : Colors.transparent;
        fg = enabled
            ? (effectiveHovered ? Colors.white : AppColors.danger)
            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
        border = Border.all(color: AppColors.danger.withValues(alpha: effectiveHovered ? 1.0 : 0.4));
        break;

      case AppButtonVariant.ghost:
        bg = widget.isSelected
            ? (isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.4))
            : (effectiveHovered
                ? (isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.4))
                : Colors.transparent);
        fg = widget.isSelected
            ? (isDark ? AppColors.darkText : AppColors.lightText)
            : (effectiveHovered
                ? (isDark ? AppColors.darkText : AppColors.lightText)
                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
        break;
    }

    final Widget content = widget.isLoading
        ? SizedBox(
            width: effectiveIconSize,
            height: effectiveIconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: effectiveIconSize, color: fg),
                if (widget.label.isNotEmpty)
                  SizedBox(width: effectiveSize == AppButtonSize.xs ? 4 : 6),
              ],
              if (widget.label.isNotEmpty)
                Text(
                  widget.label,
                  style: AppTextStyles.button.copyWith(
                    color: fg,
                    fontSize: effectiveFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          );

    final double targetScale = isMotionDisabled
        ? 1.0
        : (_isPressed
            ? 0.97
            : (effectiveHovered ? widget.hoverStyle.scale : 1.0));

    final buttonWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? _handleTap : null,
        child: AnimatedScale(
          scale: targetScale,
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standardCurve,
            height: effectiveHeight,
            width: effectiveWidth,
            padding: EdgeInsets.symmetric(horizontal: effectiveHorizPadding),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: border,
              boxShadow: isMotionDisabled ? null : shadow,
            ),
            child: Center(
              widthFactor: (widget.isFullWidth || widget.width != null) ? null : 1.0,
              child: content,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}

// ── Button Aliases ───────────────────────────────────────────────────────────
class AppPrimaryButton extends AppButton {
  const AppPrimaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.size,
    super.height,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.isSelected = false,
    super.tooltip,
    super.customColor,
    super.borderRadius,
    super.hoverStyle = AppHoverStyle.subtle,
  }) : super.primary();
}

class AppSecondaryButton extends AppButton {
  const AppSecondaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.size,
    super.height,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.isSelected = false,
    super.tooltip,
    super.customColor,
    super.borderRadius,
    super.hoverStyle = AppHoverStyle.subtle,
  }) : super.secondary();
}

class AppGhostButton extends AppButton {
  const AppGhostButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.size,
    super.height,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.isSelected = false,
    super.tooltip,
    super.customColor,
    super.borderRadius,
    super.hoverStyle = AppHoverStyle.subtle,
  }) : super.ghost();
}

class AppDangerButton extends AppButton {
  const AppDangerButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.size,
    super.height,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.isSelected = false,
    super.tooltip,
    super.customColor,
    super.borderRadius,
    super.hoverStyle = AppHoverStyle.subtle,
  }) : super.danger();
}
