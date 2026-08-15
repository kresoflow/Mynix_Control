import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class AppSegmentedTabItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppSegmentedTabItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppSegmentedTab<T> extends StatelessWidget {
  final List<AppSegmentedTabItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final double height;
  final bool isCompact;

  const AppSegmentedTab({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onValueChanged,
    this.height = 40,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          return _SegmentTabTile(
            label: item.label,
            icon: item.icon,
            isSelected: isSelected,
            isDark: isDark,
            isCompact: isCompact,
            onTap: () => onValueChanged(item.value),
          );
        }).toList(),
      ),
    );
  }
}

class _SegmentTabTile extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDark;
  final bool isCompact;
  final VoidCallback onTap;

  const _SegmentTabTile({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.isDark,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_SegmentTabTile> createState() => _SegmentTabTileState();
}

class _SegmentTabTileState extends State<_SegmentTabTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.brandPrimary;

    Color bg;
    Color fg;

    if (widget.isSelected) {
      bg = primary;
      fg = Colors.white;
    } else if (_isHovered) {
      bg = widget.isDark ? AppColors.darkCardHover : AppColors.lightBorder.withValues(alpha: 0.5);
      fg = widget.isDark ? AppColors.darkText : AppColors.lightText;
    } else {
      bg = Colors.transparent;
      fg = widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 10 : 16,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.isCompact ? 14 : 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: AppTextStyles.caption.copyWith(
                  color: fg,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: widget.isCompact ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
