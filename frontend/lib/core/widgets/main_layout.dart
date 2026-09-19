import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'main_layout/desktop_layout.dart';
import 'main_layout/mobile_layout.dart';

/// Root application shell with platform exit and back-button poka-yoke protection.
class MainLayout extends StatefulWidget {
  final Widget child;
  final String location;

  const MainLayout({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  DateTime? _lastBackPressTime;

  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop) return;

    // 1. If an internal modal/sheet/sub-route is open, pop it first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    // 2. Android back gesture at top-level: double-press to exit protection
    final now = DateTime.now();
    final isWithinWindow = _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) <= const Duration(seconds: 2);

    if (isWithinWindow) {
      await SystemNavigator.pop();
    } else {
      _lastBackPressTime = now;
      if (mounted) {
        AppToast.showInfo(
          context,
          'Нажмите «Назад» еще раз для выхода из приложения',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return DesktopLayout(
              location: widget.location,
              child: widget.child,
            );
          } else {
            return MobileLayout(
              location: widget.location,
              child: widget.child,
            );
          }
        },
      ),
    );
  }
}
