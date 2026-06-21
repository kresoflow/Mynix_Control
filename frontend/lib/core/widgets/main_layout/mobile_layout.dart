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
  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(gradient: AppColors.brandGradient),
              child: Text(
                'Mynix Control',
                style: AppTextStyles.h1.copyWith(color: const Color(0xFF0E1016)),
              ),
            ),
            _drawerTile(context, PhosphorIconsRegular.monitor, 'Касса', '/pos'),
            _drawerTile(context, PhosphorIconsRegular.cookingPot, 'Кухня', '/kitchen'),
            _drawerTile(context, PhosphorIconsRegular.bookOpen, 'Каталог', '/catalog'),
            _drawerTile(context, PhosphorIconsRegular.warehouse, 'Склад', '/warehouse'),
            _drawerTile(context, PhosphorIconsRegular.gear, 'Настройки', '/settings'),
            const Divider(),
            ListTile(
              leading: Icon(PhosphorIconsRegular.signOut, color: AppColors.danger),
              title: Text('Выйти', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
              onTap: () => context.read<AuthBloc>().add(LoggedOut()),
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkSubtext),
      title: Text(label, style: AppTextStyles.body),
      onTap: () {
        final t = DateTime.now().millisecondsSinceEpoch;
        context.go('$route?t=$t');
        Navigator.pop(context);
      },
    );
  }
}
