import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:retail_os_frontend/features/auth/bloc/auth_event.dart';
import 'icon_btn.dart';

class MynixNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MynixNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _items = [
    _NavItem(Icons.point_of_sale_outlined, Icons.point_of_sale, 'Касса'),
    _NavItem(Icons.soup_kitchen_outlined, Icons.soup_kitchen, 'Кухня'),
    _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Каталог'),
    _NavItem(Icons.warehouse_outlined, Icons.warehouse, 'Склад'),
    _NavItem(Icons.insights_outlined, Icons.insights, 'Аналитика'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Настройки'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      width: 72,
      color: bg,
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (int i = 0; i < _items.length; i++) ...[
            _NavRailItem(
              item: _items[i],
              isSelected: selectedIndex == i,
              onTap: () => onDestinationSelected(i),
              isDark: isDark,
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconBtn(
              icon: Icons.logout_rounded,
              tooltip: 'Выйти',
              color: AppColors.danger,
              onPressed: () => context.read<AuthBloc>().add(LoggedOut()),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

class _NavRailItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavRailItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavRailItem> createState() => _NavRailItemState();
}

class _NavRailItemState extends State<_NavRailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? AppColors.brandPrimary
        : _hovered
            ? (widget.isDark ? AppColors.darkText : AppColors.lightText)
            : AppColors.darkSubtext;

    final bgColor = widget.isSelected
        ? AppColors.brandPrimary.withValues(alpha: 0.1)
        : _hovered
            ? (widget.isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder)
            : Colors.transparent;

    return Tooltip(
      message: widget.item.label,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: widget.isSelected
                  ? Border.all(
                      color: AppColors.brandPrimary.withValues(alpha: 0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
                  size: 22,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: color,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
