// ==============================================================================
// Title: SearchHotkeyScopingTest
// Path: frontend/test/search_hotkey_scoping_test.dart
// Description: Тесты изоляции фокуса хоткея Ctrl+F (IndexedStack, TabBarView, раскладки).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';

class KeepAliveSearchTab extends StatefulWidget {
  final FocusNode focusNode;
  final String hintText;
  const KeepAliveSearchTab({super.key, required this.focusNode, required this.hintText});

  @override
  State<KeepAliveSearchTab> createState() => _KeepAliveSearchTabState();
}

class _KeepAliveSearchTabState extends State<KeepAliveSearchTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppSearchField(
        focusNode: widget.focusNode,
        hintText: widget.hintText,
      ),
    );
  }
}

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

    testWidgets('Ctrl+F in Russian layout (PhysicalKey.keyF) requests focus and sets cursor', (tester) async {
      final focusNode = FocusNode();
      final controller = TextEditingController();
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchField(
              focusNode: focusNode,
              controller: controller,
              hintText: 'Поиск...',
            ),
          ),
        ),
      );

      expect(focusNode.hasFocus, isFalse);

      // Нажатие Ctrl+F в русской раскладке
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
      // Курсор должен быть выставлен в нулевое положение (не invalid)
      expect(controller.selection.baseOffset, equals(0));
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

      // 1. Пока активен Экран A
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

      expect(focusNodeA.hasFocus, isTrue);
      expect(focusNodeB.hasFocus, isFalse);

      focusNodeA.unfocus();
      await tester.pumpAndSettle();

      // 2. Переключаемся на Экран B
      await tester.tap(find.text('Перейти на Экран B'));
      await tester.pumpAndSettle();

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

      expect(focusNodeB.hasFocus, isTrue);
      expect(focusNodeA.hasFocus, isFalse);
    });

    testWidgets('TabBarView scopes Ctrl+F focus strictly to active tab (Warehouse tabs bug fix)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final focusNode0 = FocusNode();
      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();
      addTearDown(focusNode0.dispose);
      addTearDown(focusNode1.dispose);
      addTearDown(focusNode2.dispose);

      final tabController = TabController(length: 3, vsync: const TestVSync());
      addTearDown(tabController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                controller: tabController,
                tabs: const [
                  Tab(text: 'Остатки'),
                  Tab(text: 'Техкарты'),
                  Tab(text: 'Поставщики'),
                ],
              ),
            ),
            body: TabBarView(
              controller: tabController,
              children: [
                KeepAliveSearchTab(focusNode: focusNode0, hintText: 'Поиск остатков'),
                KeepAliveSearchTab(focusNode: focusNode1, hintText: 'Поиск техкарт'),
                KeepAliveSearchTab(focusNode: focusNode2, hintText: 'Поиск поставщиков'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. На вкладке 0 (Остатки) — фокус получает Tab 0
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(focusNode0.hasFocus, isTrue, reason: 'Tab 0 (Остатки) должен получить фокус');
      expect(focusNode1.hasFocus, isFalse);
      expect(focusNode2.hasFocus, isFalse);

      focusNode0.unfocus();
      await tester.pumpAndSettle();

      // 2. Переключаемся на Вкладку 1 (Техкарты)
      await tester.tap(find.text('Техкарты'));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(focusNode1.hasFocus, isTrue, reason: 'Tab 1 (Техкарты) должен получить фокус');
      expect(focusNode0.hasFocus, isFalse, reason: 'Скрытый Tab 0 не должен перехватывать фокус');
      expect(focusNode2.hasFocus, isFalse);

      focusNode1.unfocus();
      await tester.pumpAndSettle();

      // 3. Переключаемся на Вкладку 2 (Поставщики)
      await tester.tap(find.text('Поставщики'));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(focusNode2.hasFocus, isTrue, reason: 'Tab 2 (Поставщики) должен получить фокус');
      expect(focusNode0.hasFocus, isFalse);
      expect(focusNode1.hasFocus, isFalse);
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

      final BuildContext context = tester.element(find.byType(Scaffold));
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Модальное окно'),
          content: Text('Контент диалога'),
        ),
      );
      await tester.pumpAndSettle();

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

      expect(backgroundFocusNode.hasFocus, isFalse);
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

      expect(find.text('Ctrl+F'), findsNothing);
    });
  });
}
