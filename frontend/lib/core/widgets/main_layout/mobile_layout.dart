import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;
  final String location;
  const MobileLayout({super.key, required this.child, required this.location});

  static const _navItems = [
    (icon: PhosphorIconsRegular.receipt, label: 'Касса', route: '/pos'),
    (icon: PhosphorIconsRegular.users, label: 'CRM', route: '/crm'),
    (icon: PhosphorIconsRegular.bookOpenText, label: 'Каталог', route: '/catalog'),
    (icon: PhosphorIconsRegular.package, label: 'Склад', route: '/warehouse'),
    (icon: PhosphorIconsRegular.chartLineUp, label: 'Аналитика', route: '/analytics'),
    (icon: PhosphorIconsRegular.gear, label: 'Настройки', route: '/settings'),
  ];

  int _getSelectedIndex(String location) {
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) => context.go(_navItems[index].route),
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.darkSubtext,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
        items: [
          for (final item in _navItems)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
