import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

enum AppBadgeVariant { success, warning, danger, info, neutral, brand }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;
  final bool hasDot;
  final double height;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
    this.hasDot = false,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case AppBadgeVariant.success:
        fg = AppColors.success;
        bg = AppColors.success.withValues(alpha: isDark ? 0.15 : 0.10);
        border = AppColors.success.withValues(alpha: isDark ? 0.30 : 0.25);
        break;
      case AppBadgeVariant.warning:
        fg = AppColors.warning;
        bg = AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.10);
        border = AppColors.warning.withValues(alpha: isDark ? 0.30 : 0.25);
        break;
      case AppBadgeVariant.danger:
        fg = AppColors.danger;
        bg = AppColors.danger.withValues(alpha: isDark ? 0.15 : 0.10);
        border = AppColors.danger.withValues(alpha: isDark ? 0.30 : 0.25);
        break;
      case AppBadgeVariant.info:
        fg = AppColors.info;
        bg = AppColors.info.withValues(alpha: isDark ? 0.15 : 0.10);
        border = AppColors.info.withValues(alpha: isDark ? 0.30 : 0.25);
        break;
      case AppBadgeVariant.brand:
        fg = AppColors.brandPrimary;
        bg = AppColors.brandPrimary.withValues(alpha: isDark ? 0.15 : 0.10);
        border = AppColors.brandPrimary.withValues(alpha: isDark ? 0.30 : 0.25);
        break;
      case AppBadgeVariant.neutral:
        fg = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
        bg = isDark ? AppColors.darkCard : AppColors.lightCard;
        border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        break;
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact KPI chip for Page Headers & Metric Toolbars
class AppKpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final bool isHighlighted;
  final Color? highlightColor;
  final VoidCallback? onTap;

  const AppKpiChip({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    this.isHighlighted = false,
    this.highlightColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = highlightColor ?? AppColors.brandPrimary;

    final child = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? effectiveColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? effectiveColor.withValues(alpha: isDark ? 0.4 : 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: iconColor ?? (isHighlighted ? effectiveColor : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isHighlighted
                  ? (isDark ? AppColors.darkText : effectiveColor)
                  : (isDark ? AppColors.darkText : AppColors.lightText),
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    }

    return child;
  }
}
