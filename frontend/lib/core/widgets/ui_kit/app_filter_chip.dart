import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';

/// ── Унифицированный чип фильтрации данных (AppFilterChip) ──────────────
class AppFilterChip extends StatefulWidget {
  final String label;
  final int? count;
  final String? countLabel;
  final IconData? icon;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    this.count,
    this.countLabel,
    this.icon,
    this.isSelected = false,
    this.isHighlighted = false,
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
    final primary = AppColors.brandPrimary;

    final countStr = widget.countLabel ?? (widget.count != null ? '${widget.count}' : null);

    Color bg;
    Color borderColor;
    Color fg;

    if (widget.isSelected) {
      bg = primary.withValues(alpha: isDark ? 0.16 : 0.12);
      borderColor = primary.withValues(alpha: isDark ? 0.5 : 0.6);
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
        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: iconColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                    letterSpacing: -0.1,
                  ),
                ),
                if (countStr != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? primary.withValues(alpha: 0.20)
                          : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadii.badge),
                    ),
                    child: Text(
                      countStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
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
