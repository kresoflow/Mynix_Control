import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'mobile_app_bar.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;
  final String location;

  const MobileLayout({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navTabs = [
      (icon: PhosphorIconsRegular.receipt, label: 'Касса', route: '/pos'),
      (icon: PhosphorIconsRegular.listNumbers, label: 'Заказы', route: '/orders'),
      (icon: PhosphorIconsRegular.squaresFour, label: 'База', route: '/hub'),
      (icon: PhosphorIconsRegular.gear, label: 'Настройки', route: '/settings'),
    ];

    int selectedIndex = 0;
    if (location.startsWith('/pos')) {
      selectedIndex = 0;
    } else if (location.startsWith('/orders')) {
      selectedIndex = 1;
    } else if (location.startsWith('/hub') ||
        location.startsWith('/kitchen') ||
        location.startsWith('/catalog') ||
        location.startsWith('/warehouse') ||
        location.startsWith('/crm') ||
        location.startsWith('/analytics')) {
      selectedIndex = 2;
    } else if (location.startsWith('/settings')) {
      selectedIndex = 3;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: const MobileAppBar(),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: (index) => context.go(navTabs[index].route),
          selectedItemColor: AppColors.brandPrimary,
          unselectedItemColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          elevation: 8,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            for (final tab in navTabs)
              BottomNavigationBarItem(
                icon: Icon(tab.icon, size: 22),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
