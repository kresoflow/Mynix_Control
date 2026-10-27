// ==============================================================================
// Title: SearchHotkeyScopingTest
// Path: frontend/test/search_hotkey_scoping_test.dart
// Description: Тесты изоляции фокуса хоткея Ctrl+F (IndexedStack, раскладки, модалки).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';

void main() {
  group('AppSearchField Scoped Hotkey Tests', () {
    testWidgets('Ctrl+F in English layout requests focus on active search field', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              focusNode: focusNode,
              hintText: 'Поиск...',
            ),
          ),
        ),
      );

      expect(focusNode.hasFocus, isFalse);

      // Нажимаем Ctrl + F (EN раскладка)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('Ctrl+F in Russian layout (PhysicalKey.keyF) requests focus', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              focusNode: focusNode,
              hintText: 'Поиск...',
            ),
          ),
        ),
      );

      expect(focusNode.hasFocus, isFalse);

      // В русской раскладке physicalKey — keyF, но logicalKey — русская буква 'а' (keyA в кодировке)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('IndexedStack scopes Ctrl+F focus strictly to active screen', (tester) async {
      final focusNodeA = FocusNode();
      final focusNodeB = FocusNode();
      addTearDown(focusNodeA.dispose);
      addTearDown(focusNodeB.dispose);

      int activeIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => activeIndex = 1),
                      child: const Text('Перейти на Экран B'),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: activeIndex,
                        children: [
                          AppSearchField(
                            key: const ValueKey('search_a'),
                            focusNode: focusNodeA,
                            hintText: 'Поиск A',
                          ),
                          AppSearchField(
                            key: const ValueKey('search_b'),
                            focusNode: focusNodeB,
                            hintText: 'Поиск B',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // 1. Пока активен Экран A (index 0) — Ctrl+F должен активировать только поиск A
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(focusNodeA.hasFocus, isTrue, reason: 'Поиск A на активном экране должен получить фокус');
      expect(focusNodeB.hasFocus, isFalse, reason: 'Скрытый поиск B не должен перехватывать фокус');

      // Снимаем фокус
      focusNodeA.unfocus();
      await tester.pumpAndSettle();
      expect(focusNodeA.hasFocus, isFalse);

      // 2. Переключаемся на Экран B (index 1)
      await tester.tap(find.text('Перейти на Экран B'));
      await tester.pumpAndSettle();

      // Нажимаем Ctrl+F снова
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(focusNodeB.hasFocus, isTrue, reason: 'Поиск B на активном экране должен получить фокус');
      expect(focusNodeA.hasFocus, isFalse, reason: 'Скрытый поиск A не должен получать фокус');
    });

    testWidgets('Background search does not intercept Ctrl+F when modal is open', (tester) async {
      final backgroundFocusNode = FocusNode();
      addTearDown(backgroundFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              focusNode: backgroundFocusNode,
              hintText: 'Фоновый поиск',
            ),
          ),
        ),
      );

      // Открываем модальный диалог
      final BuildContext context = tester.element(find.byType(Scaffold));
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Модальное окно'),
          content: Text('Контент диалога'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Модальное окно'), findsOneWidget);

      // Нажимаем Ctrl+F
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(backgroundFocusNode.hasFocus, isFalse,
          reason: 'Фоновое поле не должно перехватывать фокус при открытом модальном окне');
    });

    testWidgets('Default AppSearchField does not render Ctrl+F badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              hintText: 'Чистый поиск',
            ),
          ),
        ),
      );

      expect(find.text('Ctrl+F'), findsNothing, reason: 'Бейдж Ctrl+F не должен отображаться по умолчанию');
    });
  });
}
