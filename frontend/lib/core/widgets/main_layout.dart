import 'package:flutter/material.dart';
import 'main_layout/desktop_layout.dart';
import 'main_layout/mobile_layout.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String location;

  const MainLayout({super.key, required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return DesktopLayout(child: child, location: location);
        } else {
          return MobileLayout(child: child);
        }
      },
    );
  }
}
