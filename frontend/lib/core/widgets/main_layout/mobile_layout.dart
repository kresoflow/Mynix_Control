import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/theme/theme_bloc.dart';
import 'package:retail_os_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:retail_os_frontend/features/auth/bloc/auth_event.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;
  final String location;
  const MobileLayout({super.key, required this.child, required this.location});

  int _getSelectedIndex(String loc) {
    if (loc.startsWith('/kitchen')) return 1;
    if (loc.startsWith('/catalog')) return 2;
    if (loc.startsWith('/warehouse')) return 3;
    if (loc.startsWith('/analytics')) return 4;
    if (loc.startsWith('/settings')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mynix Control', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsRegular.sun),
            onPressed: () => context.read<ThemeBloc>().add(ThemeEvent.toggleTheme),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(gradient: AppColors.brandGradient),
              child: Text(
                'Mynix Control',
                style: AppTextStyles.h1.copyWith(color: const Color(0xFF0E1016)),
              ),
            ),
            _drawerTile(context, PhosphorIconsRegular.monitor, 'Касса', '/pos', selectedIndex == 0),
            _drawerTile(context, PhosphorIconsRegular.cookingPot, 'Кухня', '/kitchen', selectedIndex == 1),
            _drawerTile(context, PhosphorIconsRegular.bookOpen, 'Каталог', '/catalog', selectedIndex == 2),
            _drawerTile(context, PhosphorIconsRegular.warehouse, 'Склад', '/warehouse', selectedIndex == 3),
            _drawerTile(context, PhosphorIconsRegular.chartLineUp, 'Аналитика', '/analytics', selectedIndex == 4),
            _drawerTile(context, PhosphorIconsRegular.gear, 'Настройки', '/settings', selectedIndex == 5),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, String route, bool isSelected) {
    return ListTile(
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? AppColors.brandPrimary : AppColors.darkSubtext),
      title: Text(label, style: AppTextStyles.body.copyWith(
        color: isSelected ? AppColors.brandPrimary : null,
      )),
      onTap: () {
        context.go(route);
        Navigator.pop(context);
      },
    );
  }
}
