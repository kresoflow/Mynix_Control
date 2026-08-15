import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MynixNavRail extends StatelessWidget {
  final bool isOpen;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MynixNavRail({
    super.key,
    required this.isOpen,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _allItems = [
    _NavItem(PhosphorIconsRegular.receipt, PhosphorIconsFill.receipt, 'Касса', '/pos'),
    _NavItem(PhosphorIconsRegular.bookOpenText, PhosphorIconsFill.bookOpenText, 'Каталог', '/catalog'),
    _NavItem(PhosphorIconsRegular.package, PhosphorIconsFill.package, 'Склад', '/warehouse'),
    _NavItem(PhosphorIconsRegular.chartLineUp, PhosphorIconsFill.chartLineUp, 'Аналитика', '/analytics'),
    _NavItem(PhosphorIconsRegular.gear, PhosphorIconsFill.gear, 'Настройки', '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String role = 'unknown';
        if (authState is AuthAuthenticated) {
          role = authState.role.toLowerCase();
        }

        final visibleItems = _allItems.where((item) {
          if (role.contains('owner') || role.contains('superadmin') || role.contains('admin') || role.contains('manager')) return true;
          
          if (role.contains('universal')) {
            return item.route != '/settings';
          }
          if (role.contains('warehouse')) {
            return item.route == '/catalog';
          }
          if (role.contains('cashier') || role.contains('cook') || role.contains('kitchen')) {
            return item.route == '/pos';
          }
          
          return false; // Unknown role
        }).toList();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: isOpen ? 240 : 0,
          color: bg,
          child: ClipRect(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    for (int i = 0; i < visibleItems.length; i++) ...[
                      _NavSidebarItem(
                        item: visibleItems[i],
                        isSelected: _allItems.indexOf(visibleItems[i]) == selectedIndex,
                        onTap: () {
                          // Pass the ORIGINAL index so the router matches it.
                          onDestinationSelected(_allItems.indexOf(visibleItems[i]));
                        },
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.selectedIcon, this.label, this.route);
}

class _NavSidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavSidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavSidebarItem> createState() => _NavSidebarItemState();
}

class _NavSidebarItemState extends State<_NavSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brand = AppColors.brandPrimary;
    final color = widget.isSelected
        ? brand
        : _hovered
            ? (widget.isDark ? AppColors.darkText : AppColors.lightText)
            : (widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    final bgColor = widget.isSelected
        ? brand.withValues(alpha: 0.12)
        : _hovered
            ? (widget.isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.5))
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.brandPrimary.withValues(alpha: 0.25),
                    width: 1,
                  )
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
                size: 24,
                color: color,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: color,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
