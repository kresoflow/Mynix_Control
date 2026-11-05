// ==============================================================================
// ТЕСТ: Системный компонент AppExpandAllButton
// ДОМЕН: test/app_expand_all_button_test.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Проверка переключения состояний и режимов кнопки:
// 1. AppExpandAllMode.compact отображает квадратную иконку с Tooltip.
// 2. AppExpandAllMode.full отображает плашку с текстом и иконкой.
// 3. Смена isExpanded меняет иконку (caretDown -> caretUp) и текст.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  group('AppExpandAllButton Widget Tests', () {
    testWidgets('Full mode отображает текст «Развернуть все» и шеврон вниз', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppExpandAllButton(
              isExpanded: false,
              onToggle: () => toggled = true,
              mode: AppExpandAllMode.full,
            ),
          ),
        ),
      );

      expect(find.text('Развернуть все'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.caretDown), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.caretUp), findsNothing);

      await tester.tap(find.byType(AppExpandAllButton));
      expect(toggled, isTrue);
    });

    testWidgets('Full mode в раскрытом состоянии отображает «Свернуть все» и шеврон вверх', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppExpandAllButton(
              isExpanded: true,
              onToggle: () {},
              mode: AppExpandAllMode.full,
            ),
          ),
        ),
      );

      expect(find.text('Свернуть все'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.caretUp), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.caretDown), findsNothing);
    });

    testWidgets('Compact mode отображает иконку 34x34 и Tooltip без открытого текста', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppExpandAllButton(
              isExpanded: false,
              onToggle: () => toggled = true,
              mode: AppExpandAllMode.compact,
            ),
          ),
        ),
      );

      expect(find.text('Развернуть все'), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.caretDown), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(find.byType(AppExpandAllButton));
      expect(toggled, isTrue);
    });
  });
}
