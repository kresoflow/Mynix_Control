import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';

class MobileLayout extends StatelessWidget {
  final Widget child;
  final String location;
  const MobileLayout({super.key, required this.child, required this.location});

  int _getSelectedIndex(String location) {
    if (location.startsWith('/pos')) return 0;
    if (location.startsWith('/catalog')) return 1;
    if (location.startsWith('/warehouse')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/pos');
        break;
      case 1:
        context.go('/catalog');
        break;
      case 2:
        context.go('/warehouse');
        break;
      case 3:
        context.go('/analytics');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  void _showBaseMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIconsRegular.bookOpen),
              title: const Text('Каталог'),
              onTap: () {
                Navigator.pop(context);
                context.go('/catalog');
              },
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.warehouse),
              title: const Text('Склад'),
              onTap: () {
                Navigator.pop(context);
                context.go('/warehouse');
              },
            ),
            ListTile(
              leading: Icon(PhosphorIconsRegular.chartLineUp),
              title: const Text('Аналитика'),
              onTap: () {
                Navigator.pop(context);
                context.go('/analytics');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.darkSubtext,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.receipt),
            label: 'Касса',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.bookOpenText),
            label: 'Каталог',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.package),
            label: 'Склад',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.chartLineUp),
            label: 'Аналитика',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIconsRegular.gear),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
