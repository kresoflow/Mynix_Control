import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_shadows.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

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
  }) : variant = AppButtonVariant.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isPressed = false;

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

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = enabled ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
        fg = Colors.white;
        if (enabled) {
          shadow = AppShadows.buttonGlow(primary);
        }
        break;

      case AppButtonVariant.secondary:
        bg = widget.isSelected
            ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark
                ? (_isHovered ? AppColors.darkCardHover : AppColors.darkCard)
                : (_isHovered ? AppColors.lightBorder : AppColors.lightSurface));
        fg = widget.isSelected
            ? primary
            : (_isHovered && enabled
                ? primary
                : (isDark ? AppColors.darkText : AppColors.lightText));
        border = Border.all(
          color: widget.isSelected
              ? primary.withValues(alpha: 0.6)
              : (_isHovered && enabled
                  ? primary.withValues(alpha: 0.5)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        );
        if (_isHovered && enabled && !widget.isSelected) {
          shadow = [
            BoxShadow(
              color: primary.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ];
        }
        break;

      case AppButtonVariant.outline:
        bg = widget.isSelected
            ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
            : (_isHovered ? primary.withValues(alpha: 0.08) : Colors.transparent);
        fg = widget.isSelected
            ? primary
            : (enabled ? primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
        border = Border.all(
          color: widget.isSelected
              ? primary
              : (enabled
                  ? (_isHovered ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder))
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        );
        break;

      case AppButtonVariant.danger:
        bg = enabled
            ? (_isHovered ? AppColors.danger : AppColors.danger.withValues(alpha: 0.12))
            : Colors.transparent;
        fg = enabled
            ? (_isHovered ? Colors.white : AppColors.danger)
            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
        border = Border.all(color: AppColors.danger.withValues(alpha: _isHovered ? 1.0 : 0.4));
        break;

      case AppButtonVariant.ghost:
        bg = widget.isSelected
            ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
            : (_isHovered
                ? (isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.4))
                : Colors.transparent);
        fg = widget.isSelected
            ? primary
            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
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

    final buttonWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.01 : 1.0),
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: effectiveHeight,
            width: effectiveWidth,
            padding: EdgeInsets.symmetric(horizontal: effectiveHorizPadding),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: border,
              boxShadow: shadow,
            ),
            child: Center(child: content),
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
  }) : super.danger();
}
