import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_shadows.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final double height;
  final double? width;
  final bool isLoading;
  final bool isFullWidth;
  final Color? customColor;
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.height = 48,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
    this.borderRadius,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
    this.borderRadius,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
    this.borderRadius,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
    this.borderRadius,
  }) : variant = AppButtonVariant.outline;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
    this.borderRadius,
  }) : variant = AppButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 48,
    this.width,
    this.isLoading = false,
    this.isFullWidth = false,
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

    final primary = widget.customColor ?? AppColors.brandPrimary;
    final radius = widget.borderRadius ?? AppRadii.button;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = enabled ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
        fg = Colors.white;
        if (enabled) {
          shadow = AppShadows.buttonGlow(primary);
        }
        break;

      case AppButtonVariant.secondary:
        bg = isDark
            ? (_isHovered ? AppColors.darkCardHover : AppColors.darkCard)
            : (_isHovered ? AppColors.lightBorder : AppColors.lightSurface);
        fg = isDark ? AppColors.darkText : AppColors.lightText;
        border = Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
        break;

      case AppButtonVariant.outline:
        bg = _isHovered ? primary.withValues(alpha: 0.08) : Colors.transparent;
        fg = enabled ? primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
        border = Border.all(
          color: enabled
              ? (_isHovered ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder))
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
        bg = _isHovered
            ? (isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.4))
            : Colors.transparent;
        fg = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
        break;
    }

    Widget content = widget.isLoading
        ? SizedBox(
            width: 18,
            height: 18,
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
                Icon(widget.icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    return MouseRegion(
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
            height: widget.height,
            width: widget.isFullWidth ? double.infinity : widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
  }
}

// ── Legacy Aliases ───────────────────────────────────────────────────────────
class AppPrimaryButton extends AppButton {
  const AppPrimaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.height = 50,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.customColor,
    super.borderRadius = 12,
  }) : super.primary();
}

class AppSecondaryButton extends AppButton {
  const AppSecondaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.height = 48,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.customColor,
    super.borderRadius = 12,
  }) : super.secondary();
}

class AppGhostButton extends AppButton {
  const AppGhostButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.height = 48,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.customColor,
    super.borderRadius = 12,
  }) : super.ghost();
}

class AppDangerButton extends AppButton {
  const AppDangerButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.height = 48,
    super.width,
    super.isLoading = false,
    super.isFullWidth = false,
    super.customColor,
    super.borderRadius = 12,
  }) : super.danger();
}
