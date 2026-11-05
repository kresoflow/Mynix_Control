import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:kreso_frontend/features/auth/view/login_screen.dart';
import 'package:kreso_frontend/features/auth/view/splash_screen.dart';
import 'package:kreso_frontend/features/pos/view/pos_screen.dart';
import 'package:kreso_frontend/features/menu/view/catalog_screen.dart';
import 'package:kreso_frontend/features/inventory/view/warehouse_screen.dart';
import 'package:kreso_frontend/features/analytics/view/analytics_dashboard_screen.dart';
import 'package:kreso_frontend/features/settings/view/settings_screen.dart';
import 'package:kreso_frontend/features/orders/view/orders_screen.dart';
import 'package:kreso_frontend/features/hub/view/hub_screen.dart';
import 'package:kreso_frontend/core/router/app_route_observer.dart';
import 'package:kreso_frontend/core/widgets/main_layout.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: [AppRouteObserver()],
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
          return '/pos';
        }

        // Role-based access control: Cashier strictly restricted to POS & Orders history
        final role = authState.role.toLowerCase();
        if (role.contains('cashier') && currentPath != '/pos' && currentPath != '/orders') {
          return '/pos';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(location: state.uri.path, child: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pos',
                builder: (context, state) => const PosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/warehouse',
                builder: (context, state) => const WarehouseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hub',
                builder: (context, state) => const HubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
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
