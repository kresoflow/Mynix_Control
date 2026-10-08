import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_nav_tile.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

class AppNavRail extends StatelessWidget {
  final bool isOpen;
  final String location;
  final ValueChanged<String> onRouteSelected;

  const AppNavRail({
    super.key,
    required this.isOpen,
    required this.location,
    required this.onRouteSelected,
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
          // 1. Владелец / Superadmin: полный доступ
          if (role.contains('owner') || role.contains('superadmin') || role.contains('admin')) {
            return true;
          }
          // 2. Управляющий: доступ ко всему, кроме аналитики
          if (role.contains('manager')) {
            return item.route != '/analytics';
          }
          // 3. Кассир: только касса (и история внутри кассы)
          if (role.contains('cashier')) {
            return item.route == '/pos';
          }
          return false;
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in visibleItems) ...[
                        AppNavTile(
                          title: item.label,
                          icon: location.startsWith(item.route) ? item.selectedIcon : item.icon,
                          isSelected: location.startsWith(item.route),
                          size: AppNavTileSize.lg,
                          onTap: () => onRouteSelected(item.route),
                        ),
                      ],
                    ],
                  ),
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
