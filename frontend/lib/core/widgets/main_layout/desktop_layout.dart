// ==============================================================================
// Title: Desktop Layout (desktop_layout.dart)
// Path: frontend/lib/core/widgets/main_layout/desktop_layout.dart
// Description: Полноэкранный шелл для десктопа с глобальными хоткеями и сайдбаром.
// ==============================================================================

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

// ── 1. Десктопный макет приложения ──────────────────────────────────────────

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
  void initState() {
    super.initState();
    // [ИНВАРИАНТ] Глобальный слушатель аппаратных клавиш через HardwareKeyboard:
    // Работает надежно даже если primaryFocus == null (клик в пустую область),
    // поддерживает русскую раскладку через physicalKey и цифры на Numpad.
    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
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

  void _navigateTo(String targetRoute) {
    if (!mounted) return;
    if (widget.location.startsWith(targetRoute)) return;
    context.go(targetRoute);
  }

  // ── 2. Обработка глобальных хоткеев (Ctrl+1..6, Ctrl+B, Alt+1..6) ─────────────

  bool _handleGlobalHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrlOrMeta = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;

    // Хоткеи навигации срабатывают только при зажатом Ctrl/Cmd или Alt
    if (!isCtrlOrMeta && !isAlt) return false;

    // Ctrl + B / Cmd + B: Свернуть/развернуть боковую панель навигации
    // [ИНВАРИАНТ] physicalKey гарантирует срабатывание в русской раскладке (клавиша 'И')
    if (isCtrlOrMeta &&
        (event.physicalKey == PhysicalKeyboardKey.keyB ||
            event.logicalKey == LogicalKeyboardKey.keyB)) {
      _toggleSidebar();
      return true;
    }

    // Ctrl/Alt + 1..6: Быстрый переход между разделами (включая цифровой блок Numpad)
    final targetRoute = _resolveRouteForDigitKey(event);
    if (targetRoute != null) {
      _navigateTo(targetRoute);
      return true;
    }

    return false;
  }

  String? _resolveRouteForDigitKey(KeyEvent event) {
    // 1 → Касса (/pos)
    if (event.physicalKey == PhysicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.physicalKey == PhysicalKeyboardKey.numpad1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1) {
      return '/pos';
    }
    // 2 → Заказы (/orders)
    if (event.physicalKey == PhysicalKeyboardKey.digit2 ||
        event.logicalKey == LogicalKeyboardKey.digit2 ||
        event.physicalKey == PhysicalKeyboardKey.numpad2 ||
        event.logicalKey == LogicalKeyboardKey.numpad2) {
      return '/orders';
    }
    // 3 → Меню / Каталог (/catalog)
    if (event.physicalKey == PhysicalKeyboardKey.digit3 ||
        event.logicalKey == LogicalKeyboardKey.digit3 ||
        event.physicalKey == PhysicalKeyboardKey.numpad3 ||
        event.logicalKey == LogicalKeyboardKey.numpad3) {
      return '/catalog';
    }
    // 4 → Склад (/warehouse)
    if (event.physicalKey == PhysicalKeyboardKey.digit4 ||
        event.logicalKey == LogicalKeyboardKey.digit4 ||
        event.physicalKey == PhysicalKeyboardKey.numpad4 ||
        event.logicalKey == LogicalKeyboardKey.numpad4) {
      return '/warehouse';
    }
    // 5 → Аналитика (/analytics)
    if (event.physicalKey == PhysicalKeyboardKey.digit5 ||
        event.logicalKey == LogicalKeyboardKey.digit5 ||
        event.physicalKey == PhysicalKeyboardKey.numpad5 ||
        event.logicalKey == LogicalKeyboardKey.numpad5) {
      return '/analytics';
    }
    // 6 → Настройки (/settings)
    if (event.physicalKey == PhysicalKeyboardKey.digit6 ||
        event.logicalKey == LogicalKeyboardKey.digit6 ||
        event.physicalKey == PhysicalKeyboardKey.numpad6 ||
        event.logicalKey == LogicalKeyboardKey.numpad6) {
      return '/settings';
    }
    return null;
  }

  // ── 3. Построение UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
    );
  }
}
