import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'mobile_app_bar.dart';
import 'mobile_nav_drawer.dart';

class MobileLayout extends StatefulWidget {
  final Widget child;
  final String location;
  const MobileLayout({super.key, required this.child, required this.location});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = context.watch<SettingsBloc>().state;
    final showKds = settingsState.useKds && settingsState.showKdsInNav;

    final navTabs = [
      (icon: PhosphorIconsRegular.receipt, label: 'Касса', route: '/pos'),
      if (showKds) (icon: PhosphorIconsRegular.cookingPot, label: 'Кухня', route: '/kitchen')
      else (icon: PhosphorIconsRegular.clockCounterClockwise, label: 'Заказы', route: '/orders'),
      (icon: PhosphorIconsRegular.package, label: 'Склад', route: '/warehouse'),
      (icon: PhosphorIconsRegular.dotsThreeOutline, label: 'Меню', route: 'drawer'),
    ];

    int selectedIndex = 0;
    for (int i = 0; i < navTabs.length - 1; i++) {
      if (widget.location.startsWith(navTabs[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: MobileAppBar(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: MobileNavDrawer(location: widget.location),
      body: widget.child,
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
          onTap: (index) {
            if (index == navTabs.length - 1) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              context.go(navTabs[index].route);
            }
          },
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
