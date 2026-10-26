import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:kreso_frontend/core/widgets/main_layout/desktop_layout.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:kreso_frontend/features/auth/repository/auth_repository.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/repository/shift_repository.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'package:kreso_frontend/features/pos/services/pos_outbox_service.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

class _FakeDio extends Fake implements Dio {}
class _FakeAuthRepo extends AuthRepository { _FakeAuthRepo() : super(_FakeDio()); }
class _FakeShiftRepo extends ShiftRepository { _FakeShiftRepo() : super(_FakeDio()); }
class _FakeOrderRepo extends OrderRepository { _FakeOrderRepo() : super(_FakeDio()); }

class _TestAuthBloc extends AuthBloc {
  _TestAuthBloc() : super(_FakeAuthRepo()) {
    emit(const AuthAuthenticated(
      tenantId: '1',
      role: 'owner',
      permissions: ['*'],
      fullName: 'Owner',
      username: 'owner',
      tenantName: 'Test Point',
    ),);
  }
}

class _TestShiftBloc extends ShiftBloc {
  _TestShiftBloc() : super(_FakeShiftRepo()) {
    emit(ShiftInitial());
  }
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('kreso_test_hive_');
    Hive.init(tempDir.path);
    await PosOutboxService.init();
  });

  testWidgets('DesktopLayout global hotkeys navigation and sidebar toggle', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    String currentRoute = '/pos';

    final router = GoRouter(
      initialLocation: '/pos',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            currentRoute = state.uri.path;
            return DesktopLayout(
              location: state.uri.path,
              child: child,
            );
          },
          routes: [
            GoRoute(path: '/pos', builder: (_, __) => const Text('Screen POS')),
            GoRoute(path: '/orders', builder: (_, __) => const Text('Screen Orders')),
            GoRoute(path: '/catalog', builder: (_, __) => const Text('Screen Catalog')),
            GoRoute(path: '/warehouse', builder: (_, __) => const Text('Screen Warehouse')),
            GoRoute(path: '/analytics', builder: (_, __) => const Text('Screen Analytics')),
            GoRoute(path: '/settings', builder: (_, __) => const Text('Screen Settings')),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => _TestAuthBloc()),
          BlocProvider<ShiftBloc>(create: (_) => _TestShiftBloc()),
          BlocProvider<SettingsBloc>(create: (_) => SettingsBloc()),
          BlocProvider<PosTabCubit>(create: (_) => PosTabCubit(_FakeOrderRepo())),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Screen POS'), findsOneWidget);
    expect(currentRoute, '/pos');

    // 1. Test Ctrl + 2 -> /orders
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(currentRoute, '/orders');

    // 2. Test Ctrl + 3 -> /catalog
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(currentRoute, '/catalog');

    // 3. Test Ctrl + 4 -> /warehouse (using Numpad 4!)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.numpad4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.numpad4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(currentRoute, '/warehouse');

    // 4. Test Ctrl + 5 -> /analytics
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(currentRoute, '/analytics');

    // 5. Test Ctrl + 6 -> /settings
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit6);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit6);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(currentRoute, '/settings');

    // 6. Test Alt + 1 -> /pos (Web-compatible shortcut)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(currentRoute, '/pos');

    // 7. Test Ctrl + B (physical key 'keyB' toggles sidebar)
    final navRailFinder = find.byType(AnimatedContainer);
    AnimatedContainer navRail = tester.widget(navRailFinder.first);
    expect(navRail.constraints?.maxWidth ?? 0, 0); // Initially closed (width: 0)

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB, physicalKey: PhysicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB, physicalKey: PhysicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    navRail = tester.widget(navRailFinder.first);
    expect(navRail.constraints?.maxWidth ?? 240, 240); // Now open (width: 240)
  });
}
