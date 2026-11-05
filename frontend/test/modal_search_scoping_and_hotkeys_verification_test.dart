// ==============================================================================
// Title: ModalSearchScopingAndHotkeysVerificationTest
// Path: frontend/test/modal_search_scoping_and_hotkeys_verification_test.dart
// Description: Верификация автокурсора, горячих клавиш Ctrl+F и изоляции модалок.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/router/app_route_observer.dart';
import 'package:kreso_frontend/core/widgets/app_save_shortcut_scope.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';

void main() {
  group('Modal Search Scoping & Auto-cursor Tests', () {
    testWidgets('1. Фоновый поиск заблокирован при открытой модалке с DirtyPopScope', (tester) async {
      final bgController = TextEditingController();
      final bgFocusNode = FocusNode();
      addTearDown(bgController.dispose);
      addTearDown(bgFocusNode.dispose);

      final modalSearchFocusNode = FocusNode();
      addTearDown(modalSearchFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [AppRouteObserver()],
          home: Scaffold(
            body: Column(
              children: [
                AppSearchField(
                  controller: bgController,
                  focusNode: bgFocusNode,
                  mode: AppSearchMode.collapsible,
                ),
                Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: ctx,
                        builder: (_) => AppSaveShortcutScope(
                          onSearch: () => modalSearchFocusNode.requestFocus(),
                          child: DirtyPopScope(
                            isDirtyCheck: () => true, // canPop: false внутри DirtyPopScope
                            child: AlertDialog(
                              title: const Text('Модалка с защитой от сброса'),
                              content: TextField(focusNode: modalSearchFocusNode),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Открыть защищенную модалку'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Открываем диалог
      await tester.tap(find.text('Открыть защищенную модалку'));
      await tester.pumpAndSettle();

      expect(find.text('Модалка с защитой от сброса'), findsOneWidget);
      expect(AppRouteObserver.isModalOpen, isTrue);
      expect(AppSaveShortcutScope.isAnyModalOpen, isTrue);

      // Нажимаем Ctrl+F
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Фокус перешел в поле внутри модалки
      expect(modalSearchFocusNode.hasFocus, isTrue);
      // Фоновый поиск не перехватил и остался неактивным
      expect(bgFocusNode.hasFocus, isFalse);
    });

    testWidgets('2. Русская раскладка Ctrl+А (PhysicalKey.keyF) активирует onSearch в модалке', (tester) async {
      final searchFocusNode = FocusNode();
      addTearDown(searchFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveShortcutScope(
              onSearch: () => searchFocusNode.requestFocus(),
              child: AlertDialog(
                content: TextField(focusNode: searchFocusNode),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(searchFocusNode.hasFocus, isFalse);

      // Нажимаем Ctrl+А (клавиша keyF с русской буквой 'a')
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(searchFocusNode.hasFocus, isTrue);
    });

    testWidgets('3. Escape при курсоре вне текстового поля закрывает диалог через onCancel', (tester) async {
      bool cancelCalled = false;
      final buttonFocusNode = FocusNode();
      addTearDown(buttonFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveShortcutScope(
              onCancel: () => cancelCalled = true,
              child: Column(
                children: [
                  ElevatedButton(
                    focusNode: buttonFocusNode,
                    autofocus: true,
                    onPressed: () {},
                    child: const Text('Фокус на кнопке вне текстового ввода'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(buttonFocusNode.hasFocus, isTrue);

      // Нажимаем Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });
  });
}
