import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_shift_hub_modal.dart';
import 'package:mynix_frontend/features/pos/view/widgets/open_shift_modal.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: MynixAppBar(
        onCashTap: () {
          final state = context.read<ShiftBloc>().state;
          if (state is ShiftOpen) {
            showShiftHubModal(context);
          } else {
            showOpenShiftDialog(context);
          }
        },
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
            location: widget.location,
            onRouteSelected: (route) => context.go(route),
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
