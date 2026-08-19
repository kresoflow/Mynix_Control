import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';

class MynixNavRail extends StatelessWidget {
  final bool isOpen;
  final String location;
  final ValueChanged<String> onRouteSelected;

  const MynixNavRail({
    super.key,
    required this.isOpen,
    required this.location,
    required this.onRouteSelected,
  });

  static const _allItems = [
    _NavItem(PhosphorIconsRegular.receipt, PhosphorIconsFill.receipt, 'Касса', '/pos'),
    _NavItem(PhosphorIconsRegular.users, PhosphorIconsFill.users, 'CRM', '/crm'),
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
          if (role.contains('cashier')) {
            return item.route == '/pos' || item.route == '/crm';
          }
          if (role.contains('cook') || role.contains('kitchen')) {
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
                    for (final item in visibleItems) ...[
                      _NavSidebarItem(
                        item: item,
                        isSelected: location.startsWith(item.route),
                        onTap: () => onRouteSelected(item.route),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color fg = widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    Color border = Colors.transparent;

    if (widget.isSelected) {
      bg = AppColors.brandPrimary.withValues(alpha: 0.12);
      fg = AppColors.brandPrimary;
      border = AppColors.brandPrimary.withValues(alpha: 0.4);
    } else if (_isHovered) {
      bg = widget.isDark ? AppColors.darkCardHover : AppColors.lightCardHover;
      fg = widget.isDark ? AppColors.darkText : AppColors.lightText;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
                color: fg,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: fg,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
