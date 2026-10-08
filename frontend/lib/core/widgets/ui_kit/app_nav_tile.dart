import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

/// ── Размерная шкала элементов навигации и списков категорий ─────────────
enum AppNavTileSize {
  /// SM (32px): Для вложенных папок, плотных деревьев сырья, компактных фильтров
  sm(height: 32, iconSize: 15, fontSize: 12, paddingH: 10, paddingV: 4, radius: 8),

  /// MD (38-40px) [Стандарт]: Для списков категорий склада, меню настроек, боковых панелей
  md(height: 38, iconSize: 18, fontSize: 13.5, paddingH: 12, paddingV: 6, radius: 10),

  /// LG (48-52px): Для главного меню (Nav Rail), списков с подзаголовками, мобильных панелей
  lg(height: 48, iconSize: 22, fontSize: 15, paddingH: 14, paddingV: 8, radius: 12);

  final double height;
  final double iconSize;
  final double fontSize;
  final double paddingH;
  final double paddingV;
  final double radius;

  const AppNavTileSize({
    required this.height,
    required this.iconSize,
    required this.fontSize,
    required this.paddingH,
    required this.paddingV,
    required this.radius,
  });
}

/// ── Унифицированный элемент списка / навигационного дерева ──────────────
class AppNavTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final int? count;
  final String? countLabel;
  final bool isSelected;
  final int depth;
  final AppNavTileSize size;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final bool isExpandable;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;

  const AppNavTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.count,
    this.countLabel,
    this.isSelected = false,
    this.depth = 0,
    this.size = AppNavTileSize.md,
    this.onTap,
    this.onSecondaryTap,
    this.isExpandable = false,
    this.isExpanded = false,
    this.onExpandToggle,
  });

  @override
  State<AppNavTile> createState() => _AppNavTileState();
}

class _AppNavTileState extends State<AppNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = widget.size;

    // Цветовая палитра
    final primary = AppColors.brandPrimary;
    final defaultTextColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedTextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final activeBg = primary.withValues(alpha: isDark ? 0.14 : 0.10);
    final hoverBg = isDark ? AppColors.darkCardHover : AppColors.lightCardHover;

    Color bgColor = Colors.transparent;
    if (widget.isSelected) {
      bgColor = activeBg;
    } else if (_isHovered) {
      bgColor = hoverBg;
    }

    final textColor = widget.isSelected
        ? (isDark ? AppColors.darkText : primary)
        : defaultTextColor;

    final iconColor = widget.isSelected ? primary : mutedTextColor;

    final countText = widget.countLabel ?? (widget.count != null ? '${widget.count}' : null);

    return Padding(
      padding: EdgeInsets.only(
        left: widget.depth * 12.0,
        bottom: 2.0,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onSecondaryTap: widget.onSecondaryTap,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(size.radius),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standardCurve,
                constraints: BoxConstraints(minHeight: size.height),
                padding: EdgeInsets.symmetric(
                  horizontal: size.paddingH,
                  vertical: size.paddingV,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(size.radius),
                  border: widget.isSelected
                      ? Border.all(color: primary.withValues(alpha: isDark ? 0.25 : 0.35), width: 1)
                      : Border.all(color: Colors.transparent, width: 1),
                ),
                child: Row(
                  children: [
                    // Шеврон раскрытия (если папка)
                    if (widget.isExpandable) ...[
                      InkWell(
                        onTap: widget.onExpandToggle,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            widget.isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            size: size.iconSize,
                            color: mutedTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Иконка или кастомный leading
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 8),
                    ] else if (widget.icon != null) ...[
                      Icon(widget.icon, size: size.iconSize, color: iconColor),
                      const SizedBox(width: 8),
                    ],

                    // Название и подзаголовок
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.inter(
                              fontSize: size.fontSize,
                              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: textColor,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              widget.subtitle!,
                              style: GoogleFonts.inter(
                                fontSize: size.fontSize * 0.85,
                                fontWeight: FontWeight.w400,
                                color: mutedTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Бейдж счетчика (если есть)
                    if (countText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? primary.withValues(alpha: 0.16)
                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppRadii.badge),
                        ),
                        child: Text(
                          countText,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: size.fontSize * 0.82,
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected ? primary : mutedTextColor,
                          ),
                        ),
                      ),
                    ],

                    // Дополнительный виджет справа
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 6),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}