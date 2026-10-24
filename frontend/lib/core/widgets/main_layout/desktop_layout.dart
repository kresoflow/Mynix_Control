import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/view/widgets/pos_shift_hub_modal.dart';
import 'package:kreso_frontend/features/pos/view/widgets/open_shift_modal.dart';
import 'app_nav_bar.dart';
import 'app_nav_rail.dart';

class DesktopLayout extends StatefulWidget {
  final Widget child;
  final String location;

  const DesktopLayout({super.key, required this.child, required this.location});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  // [ИНВАРИАНТ] ValueNotifier вместо setState — изменение флага сайдбара
  // НЕ вызывает rebuild AppNavBar (логотип, сегментированный контрол, etc.).
  // Перестраивается только ValueListenableBuilder вокруг AppNavRail.
  final _sidebarNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _sidebarNotifier.dispose();
    super.dispose();
  }

  void _handleCashTap() {
    final state = context.read<ShiftBloc>().state;
    if (state is ShiftOpen) {
      showShiftHubModal(context);
    } else {
      showOpenShiftDialog(context);
    }
  }

  void _toggleSidebar() {
    _sidebarNotifier.value = !_sidebarNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => context.go('/pos'),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => context.go('/orders'),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => context.go('/catalog'),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => context.go('/warehouse'),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => context.go('/analytics'),
        const SingleActivator(LogicalKeyboardKey.digit6, control: true): () => context.go('/settings'),
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () => context.go('/pos'),
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () => context.go('/orders'),
        const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () => context.go('/catalog'),
        const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () => context.go('/warehouse'),
        const SingleActivator(LogicalKeyboardKey.digit5, meta: true): () => context.go('/analytics'),
        const SingleActivator(LogicalKeyboardKey.digit6, meta: true): () => context.go('/settings'),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): _toggleSidebar,
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): _toggleSidebar,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
          // AppNavBar получает стабильные ссылки на методы — не пересоздаётся
          // при каждом rebuild. Логотип и сегментированный контрол не дёргаются.
          appBar: AppNavBar(
            location: widget.location,
            onCashTap: _handleCashTap,
            onToggleSidebar: _toggleSidebar,
          ),
          body: Row(
            children: [
              // Только AppNavRail обновляется при открытии/закрытии сайдбара
              ValueListenableBuilder<bool>(
                valueListenable: _sidebarNotifier,
                builder: (context, isOpen, _) => AppNavRail(
                  isOpen: isOpen,
                  location: widget.location,
                  onRouteSelected: (route) => context.go(route),
                ),
              ),
              Container(
                width: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
