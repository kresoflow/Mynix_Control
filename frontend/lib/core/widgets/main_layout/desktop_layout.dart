import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'cashbox_modal.dart';
import 'mynix_app_bar.dart';
import 'mynix_nav_rail.dart';

class DesktopLayout extends StatefulWidget {
  final Widget child;
  final String location;

  const DesktopLayout({super.key, required this.child, required this.location});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  bool _isSidebarOpen = false;

  int _getSelectedIndex(String location) {
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/kitchen')) return 2;
    if (location.startsWith('/catalog')) return 3;
    if (location.startsWith('/warehouse')) return 4;
    if (location.startsWith('/analytics')) return 5;
    if (location.startsWith('/settings')) return 6;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = widget.location;
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: MynixAppBar(
        onCashTap: () => showCashboxModal(context),
        onToggleSidebar: () {
          setState(() {
            _isSidebarOpen = !_isSidebarOpen;
          });
        },
      ),
      body: Row(
        children: [
          MynixNavRail(
            isOpen: _isSidebarOpen,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              final routes = ['/pos', '/orders', '/kitchen', '/catalog', '/warehouse', '/analytics', '/settings'];
              context.go(routes[index]);
            },
          ),
          Container(
            width: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
