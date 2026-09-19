import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';

/// ── Размерная шкала сегментированных переключателей ─────────────────────
enum AppSegmentedSize {
  /// SM (32px): Компактный для форм, диалогов и таблиц
  sm(height: 32, iconSize: 14, fontSize: 12, paddingH: 10, radius: 8),

  /// MD (38-40px) [Стандарт]: Для тулбаров, шапок экранов и POS-переключателей
  md(height: 38, iconSize: 17, fontSize: 13.5, paddingH: 14, radius: 10),

  /// LG (46-48px): Просторный для главных экранов и POS-способов оплаты
  lg(height: 46, iconSize: 20, fontSize: 15, paddingH: 18, radius: 12);

  final double height;
  final double iconSize;
  final double fontSize;
  final double paddingH;
  final double radius;

  const AppSegmentedSize({
    required this.height,
    required this.iconSize,
    required this.fontSize,
    required this.paddingH,
    required this.radius,
  });
}

/// ── Элемент сегментированного переключателя ─────────────────────────────
class AppSegmentedItem<T> {
  final T value;
  final String label;
  final String? tooltip;
  final IconData? icon;
  final int? count;

  const AppSegmentedItem({
    required this.value,
    this.label = '',
    this.tooltip,
    this.icon,
    this.count,
  });
}

/// ── Унифицированный сегментированный переключатель режимов ──────────────
class AppSegmentedControl<T> extends StatelessWidget {
  final List<AppSegmentedItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final AppSegmentedSize size;
  final bool isExpanded;

  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onValueChanged,
    this.size = AppSegmentedSize.md,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkTrackBg : AppColors.lightTrackBg;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final children = items.map((item) {
      final isSelected = item.value == selectedValue;
      final tile = _SegmentTile<T>(
        item: item,
        isSelected: isSelected,
        size: size,
        isDark: isDark,
        onTap: () => onValueChanged(item.value),
      );

      return isExpanded ? Expanded(child: tile) : tile;
    }).toList();

    return Container(
      height: size.height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size.radius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: isExpanded
          ? Row(children: children)
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SegmentTile<T> extends StatefulWidget {
  final AppSegmentedItem<T> item;
  final bool isSelected;
  final AppSegmentedSize size;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentTile({
    required this.item,
    required this.isSelected,
    required this.size,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SegmentTile<T>> createState() => _SegmentTileState<T>();
}

class _SegmentTileState<T> extends State<_SegmentTile<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.brandPrimary;
    final size = widget.size;
    final isSelected = widget.isSelected;
    final item = widget.item;
    final isIconOnly = item.label.isEmpty && item.icon != null;

    Color bg;
    Color fg;
    List<BoxShadow> shadows = [];

    if (isSelected) {
      bg = primary;
      fg = Colors.white;
      shadows = AppShadows.buttonGlow(primary);
    } else if (_isHovered) {
      bg = widget.isDark ? AppColors.darkCardHover : AppColors.lightCardHover;
      fg = widget.isDark ? AppColors.darkText : AppColors.lightText;
    } else {
      bg = Colors.transparent;
      fg = widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    }

    final tileHeight = size.height - 6;
    final tileWidth = isIconOnly ? tileHeight : null;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: tileWidth,
      height: tileHeight,
      padding: isIconOnly ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: size.paddingH),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size.radius - 2),
        boxShadow: shadows,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: size.iconSize, color: fg),
            if (!isIconOnly) const SizedBox(width: 6),
          ],
          if (!isIconOnly)
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: size.fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: fg,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (item.count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadii.badge),
              ),
              child: Text(
                '${item.count}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: size.fontSize * 0.8,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (item.tooltip != null) {
      content = Tooltip(
        message: item.tooltip!,
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(size.radius - 2),
          child: content,
        ),
      ),
    );
  }
}
