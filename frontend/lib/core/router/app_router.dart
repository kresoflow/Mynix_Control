import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/features/auth/view/login_screen.dart';
import 'package:mynix_frontend/features/auth/view/splash_screen.dart';
import 'package:mynix_frontend/features/pos/view/pos_screen.dart';
import 'package:mynix_frontend/features/kitchen/view/kitchen_screen.dart';
import 'package:mynix_frontend/features/menu/view/catalog_screen.dart';
import 'package:mynix_frontend/features/inventory/view/warehouse_screen.dart';
import 'package:mynix_frontend/features/analytics/view/analytics_dashboard_screen.dart';
import 'package:mynix_frontend/features/settings/view/settings_screen.dart';
import 'package:mynix_frontend/features/orders/view/orders_screen.dart';
import 'package:mynix_frontend/features/crm/view/crm_screen.dart';
import 'package:mynix_frontend/features/hub/view/hub_screen.dart';
import 'package:mynix_frontend/core/widgets/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final currentPath = state.uri.path;
      final isGoingToLogin = currentPath == '/login';
      final isGoingToSplash = currentPath == '/splash';

      // 1. Initial cold startup check: keep on splash
      if (authState is AuthInitial) {
        return isGoingToSplash ? null : '/splash';
      }

      // 2. Loading state:
      // If we are already on splash during initial app startup, stay on splash.
      // If we are submitting login form on /login, stay on login so button shows spinner.
      if (authState is AuthLoading) {
        if (isGoingToSplash) return null;
        if (isGoingToLogin) return null;
        return '/splash';
      }

      // 3. Unauthenticated or Error: redirect to login
      if ((authState is AuthUnauthenticated || authState is AuthError || authState is AuthFailure) && !isGoingToLogin) {
        return '/login';
      }

      // 3. Authenticated:
      if (authState is AuthAuthenticated) {
        if (isGoingToLogin || isGoingToSplash || currentPath == '/') {
          final role = authState.role.toLowerCase();
          if (role.contains('cook') || role.contains('kitchen')) {
            return '/kitchen';
          }
          return '/pos';
        }

        // Role-based access control
        final role = authState.role.toLowerCase();
        if (role.contains('cashier') && currentPath != '/pos') {
          return '/pos';
        }
        if ((role.contains('cook') || role.contains('kitchen')) && currentPath != '/kitchen') {
          return '/kitchen';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/pos',
            builder: (context, state) => const PosScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/crm',
            builder: (context, state) => const CrmScreen(),
          ),
          GoRoute(
            path: '/kitchen',
            builder: (context, state) => const KitchenScreen(),
          ),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => const CatalogScreen(),
          ),
          GoRoute(
            path: '/warehouse',
            builder: (context, state) => const WarehouseScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsDashboardScreen(),
          ),
          GoRoute(
            path: '/hub',
            builder: (context, state) => const HubScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
