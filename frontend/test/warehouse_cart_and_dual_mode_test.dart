// ==============================================================================
// Title: WarehouseCartAndDualModeTest
// Path: frontend/test/warehouse_cart_and_dual_mode_test.dart
// Description: Тестирование выдвижных корзин и двухрежимного ввода склада.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_card_dialog.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/blind_inventory/blind_inventory_cart_sheet.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/blind_inventory/blind_inventory_tabs_bar.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/write_off/write_off_cart_sheet.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/write_off/write_off_items_table.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/write_off/write_off_summary_card.dart';

void main() {
  group('WriteOff Cart Sheet & Summary Tests', () {
    testWidgets('1. WriteOffSummaryCard отображает кнопку корзины и реагирует на нажатие', (tester) async {
      bool cartToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WriteOffSummaryCard(
              itemsCount: 3,
              totalUnits: 15.0,
              totalAmount: 1200.0,
              currency: 'с',
              isCartOpen: false,
              onToggleCart: () => cartToggled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 поз.'), findsOneWidget);
      expect(find.text('Всего: 15 ед.'), findsOneWidget);
      expect(find.text('1200.00 с'), findsOneWidget);

      await tester.tap(find.text('3 поз.'));
      await tester.pumpAndSettle();

      expect(cartToggled, isTrue);
    });

    testWidgets('2. WriteOffCartSheet отображает список позиций и позволяет менять количество', (tester) async {
      final ing1 = Ingredient(id: 1, name: 'Кофе зерновой', costPerUnit: 200, unit: 'кг', currentStock: 10.0, minStockAlert: 2.0, isLowStock: false);
      final ing2 = Ingredient(id: 2, name: 'Молоко 3.2%', costPerUnit: 80, unit: 'л', currentStock: 20.0, minStockAlert: 5.0, isLowStock: false);

      final entry1 = WriteOffItemEntry(item: ing1, quantity: 2.0);
      final entry2 = WriteOffItemEntry(item: ing2, quantity: 5.0);

      bool changed = false;
      int? removedIndex;
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                WriteOffCartSheet(
                  items: [entry1, entry2],
                  currency: 'с',
                  onRemove: (idx) => removedIndex = idx,
                  onChanged: () => changed = true,
                  onClose: () => closed = true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Состав акта списания'), findsOneWidget);
      expect(find.text('2 поз.'), findsOneWidget);
      expect(find.text('Кофе зерновой'), findsOneWidget);
      expect(find.text('Молоко 3.2%'), findsOneWidget);

      // Нажимаем [+] у первой позиции
      await tester.tap(find.byIcon(PhosphorIconsBold.plus).first);
      await tester.pumpAndSettle();
      expect(changed, isTrue);
      expect(entry1.quantity, 3.0);

      // Нажимаем удалить у первой позиции
      await tester.tap(find.byTooltip('Удалить из списания').first);
      await tester.pumpAndSettle();
      expect(removedIndex, 0);

      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });
  });

  group('Blind Inventory Dual Mode & Cart Sheet Tests', () {
    testWidgets('3. BlindInventoryTabsBar переключает режимы По позициям / По категориям', (tester) async {
      BlindInventoryViewMode currentMode = BlindInventoryViewMode.items;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BlindInventoryTabsBar(
                  viewMode: currentMode,
                  onViewModeChanged: (mode) => setState(() => currentMode = mode),
                  filledCount: 4,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('По позициям'), findsOneWidget);
      expect(find.text('По категориям'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(currentMode, equals(BlindInventoryViewMode.items));

      // Переключаем на категории
      await tester.tap(find.text('По категориям'));
      await tester.pumpAndSettle();

      expect(currentMode, equals(BlindInventoryViewMode.categories));
    });

    testWidgets('4. BlindInventoryCartSheet отображает посчитанные остатки и позволяет сбросить позицию', (tester) async {
      final ing = Ingredient(id: 10, name: 'Сахар белый', costPerUnit: 50, unit: 'кг', currentStock: 30.0, minStockAlert: 5.0, isLowStock: false);
      final controllers = <String, TextEditingController>{
        ing.uniqueKey: TextEditingController(text: '12.5'),
      };

      Ingredient? removedItem;
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BlindInventoryCartSheet(
                  allItems: [ing],
                  controllers: controllers,
                  onRemove: (it) => removedItem = it,
                  onChanged: () {},
                  onClose: () => closed = true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Посчитанные остатки ревизии'), findsOneWidget);
      expect(find.text('Сахар белый'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);

      await tester.tap(find.byTooltip('Сбросить остаток'));
      await tester.pumpAndSettle();

      expect(removedItem?.id, equals(10));

      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('5. AppCardDialog корректно отображает overlay шторки без Material ошибок', (tester) async {
      final ing = Ingredient(
        id: 99,
        name: 'Чай черный',
        unit: 'кг',
        categoryName: 'Напитки',
        costPerUnit: 500,
        currentStock: 5.0,
        minStockAlert: 1.0,
        isLowStock: false,
      );

      bool cartOpen = true;
      final controllers = {'ingredient_99': TextEditingController(text: '3.0')};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (_) => StatefulBuilder(
                        builder: (context, setState) {
                          return AppCardDialog(
                            title: 'Слепая Инвентаризация',
                            icon: PhosphorIconsRegular.clipboardText,
                            width: 680,
                            overlay: cartOpen
                                ? BlindInventoryCartSheet(
                                    allItems: [ing],
                                    controllers: controllers,
                                    onRemove: (_) {},
                                    onClose: () => setState(() => cartOpen = false),
                                    onChanged: () {},
                                  )
                                : null,
                            body: const SizedBox(height: 300, child: Text('Контент инвентаризации')),
                            actions: const [],
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Открыть диалог'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Открываем диалог со шторкой-корзиной внутри AppCardDialog
      await tester.tap(find.text('Открыть диалог'));
      await tester.pumpAndSettle();

      // Проверяем, что нет ошибок Material и шторка успешно отрендерилась
      expect(find.text('Посчитанные остатки ревизии'), findsOneWidget);
      expect(find.text('Чай черный'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Закрываем шторку
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();

      // Шторка скрылась, виден основной контент
      expect(find.text('Посчитанные остатки ревизии'), findsNothing);
      expect(find.text('Контент инвентаризации'), findsOneWidget);
    });
  });
}
