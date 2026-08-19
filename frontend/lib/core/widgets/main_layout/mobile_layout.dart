import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;
  final String location;
  const MobileLayout({super.key, required this.child, required this.location});

  static const _rawNavItems = [
    (icon: PhosphorIconsRegular.receipt, label: 'Касса', route: '/pos'),
    (icon: PhosphorIconsRegular.cookingPot, label: 'Кухня', route: '/kitchen'),
    (icon: PhosphorIconsRegular.bookOpenText, label: 'Каталог', route: '/catalog'),
    (icon: PhosphorIconsRegular.package, label: 'Склад', route: '/warehouse'),
    (icon: PhosphorIconsRegular.chartLineUp, label: 'Аналитика', route: '/analytics'),
    (icon: PhosphorIconsRegular.users, label: 'CRM', route: '/crm'),
    (icon: PhosphorIconsRegular.gear, label: 'Настройки', route: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final showKds = settingsState.useKds && settingsState.showKdsInNav;

    final navItems = _rawNavItems.where((item) {
      if (item.route == '/kitchen' && !showKds) return false;
      return true;
    }).toList();

    int selectedIndex = 0;
    for (int i = 0; i < navItems.length; i++) {
      if (location.startsWith(navItems[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) => context.go(navItems[index].route),
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.darkSubtext,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
        items: [
          for (final item in navItems)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
