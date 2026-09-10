import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';

enum AppFilterChipSize {
  sm,
  md,
  lg,
}

/// ── Унифицированный чип фильтрации данных (AppFilterChip) ──────────────
class AppFilterChip extends StatefulWidget {
  final String label;
  final int? count;
  final String? countLabel;
  final IconData? icon;
  final bool isSelected;
  final bool isHighlighted;
  final Color? activeColor;
  final AppFilterChipSize size;
  final VoidCallback? onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    this.count,
    this.countLabel,
    this.icon,
    this.isSelected = false,
    this.isHighlighted = false,
    this.activeColor,
    this.size = AppFilterChipSize.md,
    this.onTap,
  });

  @override
  State<AppFilterChip> createState() => _AppFilterChipState();
}

class _AppFilterChipState extends State<AppFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = widget.activeColor ?? AppColors.brandPrimary;

    final countStr = widget.countLabel ?? (widget.count != null ? '${widget.count}' : null);

    Color bg;
    Color borderColor;
    Color fg;

    if (widget.isSelected) {
      bg = primary.withValues(alpha: isDark ? 0.16 : 0.12);
      borderColor = primary.withValues(alpha: isDark ? 0.65 : 0.70);
      fg = isDark ? AppColors.darkText : primary;
    } else if (_isHovered) {
      bg = isDark ? AppColors.darkCardHover : AppColors.lightCardHover;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      fg = isDark ? AppColors.darkText : AppColors.lightText;
    } else {
      bg = isDark ? AppColors.darkCard : AppColors.lightCard;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      fg = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    }

    final iconColor = widget.isSelected
        ? primary
        : (_isHovered
            ? (isDark ? AppColors.darkText : AppColors.lightText)
            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));

    // Size metrics
    final double height;
    final EdgeInsets padding;
    final double fontSize;
    final double iconSize;
    final EdgeInsets badgePadding;
    final double badgeFontSize;
    final double itemSpacing;

    switch (widget.size) {
      case AppFilterChipSize.sm:
        height = 26.0;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2);
        fontSize = 11.0;
        iconSize = 12.0;
        badgePadding = const EdgeInsets.symmetric(horizontal: 4, vertical: 1);
        badgeFontSize = 9.5;
        itemSpacing = 4.0;
        break;
      case AppFilterChipSize.md:
        height = 32.0;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4);
        fontSize = 12.5;
        iconSize = 14.0;
        badgePadding = const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5);
        badgeFontSize = 10.5;
        itemSpacing = 6.0;
        break;
      case AppFilterChipSize.lg:
        height = 40.0;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6);
        fontSize = 14.0;
        iconSize = 16.0;
        badgePadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        badgeFontSize = 12.0;
        itemSpacing = 8.0;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.2 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: iconSize, color: iconColor),
                  SizedBox(width: itemSpacing),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                    letterSpacing: -0.1,
                  ),
                ),
                if (countStr != null) ...[
                  SizedBox(width: itemSpacing),
                  Container(
                    padding: badgePadding,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? primary.withValues(alpha: isDark ? 0.22 : 0.16)
                          : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadii.badge),
                    ),
                    child: Text(
                      countStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.w700,
                        color: widget.isSelected ? primary : fg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ── Горизонтальная строка фильтров (AppFilterBar) ──────────────────────
class AppFilterBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const AppFilterBar({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

/// ── Чип контекста заказа (Стол / Гость / Тип заказа) ────────────────────
class AppOrderContextChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const AppOrderContextChip({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.brandPrimary;

    final bg = isSelected
        ? primary.withValues(alpha: isDark ? 0.16 : 0.12)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final borderColor = isSelected
        ? primary.withValues(alpha: isDark ? 0.5 : 0.6)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final fg = isSelected
        ? (isDark ? AppColors.darkText : primary)
        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
    final iconColor = isSelected ? primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null && isSelected) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
