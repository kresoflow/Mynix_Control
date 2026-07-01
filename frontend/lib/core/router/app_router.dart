import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/features/auth/view/login_screen.dart';
import 'package:mynix_frontend/features/pos/view/pos_screen.dart';
import 'package:mynix_frontend/features/kitchen/view/kitchen_screen.dart';
import 'package:mynix_frontend/features/menu/view/catalog_screen.dart';
import 'package:mynix_frontend/features/inventory/view/warehouse_screen.dart';
import 'package:mynix_frontend/features/analytics/view/analytics_dashboard_screen.dart';
import 'package:mynix_frontend/features/settings/view/settings_screen.dart';
import 'package:mynix_frontend/core/widgets/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/pos',
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isGoingToLogin = state.uri.path == '/login';

      if (authState is AuthUnauthenticated && !isGoingToLogin) {
        return '/login';
      }

      if (authState is AuthAuthenticated && isGoingToLogin) {
        return '/pos';
      }
      
      // If going to root, redirect to pos
      if (authState is AuthAuthenticated && state.uri.path == '/') {
        return '/pos';
      }

      return null;
    },
    routes: [
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
