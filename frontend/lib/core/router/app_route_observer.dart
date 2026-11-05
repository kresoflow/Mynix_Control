// ==============================================================================
// Title: AppRouteObserver (app_route_observer.dart)
// Path: frontend/lib/core/router/app_route_observer.dart
// Description: Наблюдатель маршрутов для изоляции фонового поиска при открытых диалогах.
// ==============================================================================

import 'package:flutter/material.dart';

/// [ИНВАРИАНТ] Глобальный наблюдатель модальных маршрутов (showDialog, PopupRoute).
class AppRouteObserver extends NavigatorObserver {
  static int _openModals = 0;

  /// Открыто ли хотя бы одно модальное окно/диалог поверх основных экранов.
  static bool get isModalOpen => _openModals > 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      _openModals++;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute && _openModals > 0) {
      _openModals--;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute && _openModals > 0) {
      _openModals--;
    }
  }
}
