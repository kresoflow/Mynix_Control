// ==============================================================================
// ТЕСТ: Search Esc Hierarchy and Modal Category Hotkeys
// ДОМЕН: test/search_esc_hierarchy_and_modal_hotkeys_test.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/core/widgets/app_save_shortcut_scope.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/blind_inventory/blind_inventory_toolbar.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/receive_category_section.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/receive_category_sync_adapter.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/receive_category_toolbar.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receipt_row_data.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/receive_document/receive_document_autocomplete_view.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/dialogs/write_off/write_off_category_toolbar.dart';

class _FakeCategoryBloc extends Bloc<CategoryEvent, CategoryState> implements CategoryBloc {
  _FakeCategoryBloc() : super(const CategoryLoaded(categories: []));
  @override
  InventoryRepository get repository => throw UnimplementedError();
}

void main() {
  group('AppSearchField Cascading Escape Hierarchy Tests', () {
    testWidgets('1. Escape в поле с текстом очищает текст, сохраняя фокус', (tester) async {
      final controller = TextEditingController(text: 'Молоко');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      bool modalCancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveShortcutScope(
              onCancel: () => modalCancelled = true,
              child: AppSearchField(
                controller: controller,
                focusNode: focusNode,
                autoFocus: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
      expect(controller.text, 'Молоко');

      // Нажимаем Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Текст должен быть очищен
      expect(controller.text, isEmpty);
      // Фокус остаётся в поле для ввода нового запроса
      expect(focusNode.hasFocus, isTrue);
      // Родительская модалка НЕ закрыта
      expect(modalCancelled, isFalse);
    });

    testWidgets('2. Escape в пустом сфокусированном поле снимает фокус и сворачивает collapsible', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      bool modalCancelled = false;
      bool isExpanded = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveShortcutScope(
              onCancel: () => modalCancelled = true,
              child: AppSearchField(
                focusNode: focusNode,
                mode: AppSearchMode.collapsible,
                isInitiallyExpanded: true,
                autoFocus: true,
                onExpandedChanged: (val) => isExpanded = val,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);

      // Нажимаем Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Фокус снят, поле свернуто
      expect(focusNode.hasFocus, isFalse);
      expect(isExpanded, isFalse);
      // Родительская модалка не тронута
      expect(modalCancelled, isFalse);
    });

    testWidgets('3. Escape при расфокусированном поиске всплывает в модалку и закрывает её', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      bool modalCancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveShortcutScope(
              onCancel: () => modalCancelled = true,
              child: Column(
                children: [
                  AppSearchField(
                    focusNode: focusNode,
                    autoFocus: false,
                  ),
                  const ElevatedButton(onPressed: null, child: Text('Другой элемент')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);

      // Нажимаем Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Модалка перехватила Escape и выполнила отмену/закрытие
      expect(modalCancelled, isTrue);
    });

    testWidgets('4. [МУЛЬТИКОЛОНКИ] Escape сворачивает ТОЛЬКО сфокусированное поле, не трогая второе', (tester) async {
      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();
      addTearDown(focusNode1.dispose);
      addTearDown(focusNode2.dispose);

      bool expanded1 = true;
      bool expanded2 = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                // Колонка 1: Сайдбар категорий
                AppSearchField(
                  focusNode: focusNode1,
                  mode: AppSearchMode.collapsible,
                  isInitiallyExpanded: true,
                  onExpandedChanged: (val) => expanded1 = val,
                ),
                // Колонка 2: Список блюд
                AppSearchField(
                  focusNode: focusNode2,
                  mode: AppSearchMode.collapsible,
                  isInitiallyExpanded: true,
                  autoFocus: true, // Фокус во втором поле
                  onExpandedChanged: (val) => expanded2 = val,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(focusNode1.hasFocus, isFalse);
      expect(focusNode2.hasFocus, isTrue);

      // Нажимаем Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Поле 2 свернулось и потеряло фокус
      expect(focusNode2.hasFocus, isFalse);
      expect(expanded2, isFalse);

      // [ИНВАРИАНТ] Поле 1 ОСТАЛОСЬ РАСКРЫТЫМ! Оно не схлопнулось самопроизвольно!
      expect(expanded1, isTrue);
    });

    testWidgets('5. Escape при курсоре ВНЕ поля закрывает развёрнутый collapsible-поиск', (tester) async {
      final focusNode = FocusNode();
      final buttonFocusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(buttonFocusNode.dispose);

      bool isExpanded = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppSearchField(
                  focusNode: focusNode,
                  mode: AppSearchMode.collapsible,
                  isInitiallyExpanded: true,
                  autoFocus: false,
                  onExpandedChanged: (val) => isExpanded = val,
                ),
                ElevatedButton(
                  focusNode: buttonFocusNode,
                  autofocus: true,
                  onPressed: () {},
                  child: const Text('Кнопка вне поиска'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);
      expect(buttonFocusNode.hasFocus, isTrue);
      expect(isExpanded, isTrue);

      // Нажимаем Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Развёрнутый поиск сворачивается даже когда курсор был вне поля
      expect(isExpanded, isFalse);
    });
  });

  group('Modal Documents Category Toolbars Hotkeys & Badges Tests', () {
    testWidgets('ReceiveCategoryToolbar НЕ отображает бейдж Ctrl+F (чистый UI)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiveCategoryToolbar(
              searchController: controller,
              onSearchChanged: (_) {},
              activeFilter: ReceiveCategoryFilter.all,
              onFilterChanged: (_) {},
              deficitCount: 0,
              inReceiptCount: 0,
              isAllExpanded: false,
              onToggleExpandAll: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // [UX] Визуальный бейдж убран во избежание визуального мусора
      expect(find.text('Ctrl+F'), findsNothing);
    });

    testWidgets('WriteOffCategoryToolbar НЕ отображает бейдж Ctrl+F (чистый UI)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WriteOffCategoryToolbar(
              searchController: controller,
              onSearchChanged: (_) {},
              activeFilter: WriteOffCategoryFilter.all,
              onFilterChanged: (_) {},
              inActCount: 0,
              inStockCount: 0,
              isAllExpanded: false,
              onToggleExpandAll: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ctrl+F'), findsNothing);
    });

    testWidgets('BlindInventoryToolbar НЕ отображает бейдж Ctrl+F (чистый UI)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlindInventoryToolbar(
              searchQuery: '',
              onSearchChanged: (_) {},
              activeFilter: BlindInventoryFilter.all,
              onFilterChanged: (_) {},
              unfilledCount: 0,
              filledCount: 0,
              isAllExpanded: false,
              onToggleExpandAll: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ctrl+F'), findsNothing);
    });

    testWidgets('Переключение вкладок в ReceiveCategorySection автоматически восстанавливает фокус в поиске', (tester) async {
      final items = <ReceiptRowData>[];
      final adapter = ReceiveCategorySyncAdapter(items: items, onTotalChanged: () {});
      final catBloc = _FakeCategoryBloc();
      addTearDown(catBloc.close);

      final dummyIngredient1 = Ingredient(
        id: 1,
        name: 'Сыр',
        costPerUnit: 100,
        unit: 'кг',
        currentStock: 10,
        minStockAlert: 2,
        isLowStock: false,
        attributes: const {'is_retail': false},
      );
      final dummyIngredient2 = Ingredient(
        id: 2,
        name: 'Вода',
        costPerUnit: 50,
        unit: 'шт',
        currentStock: 20,
        minStockAlert: 5,
        isLowStock: false,
        attributes: const {'is_retail': true},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<CategoryBloc>.value(
              value: catBloc,
              child: Column(
                children: [
                  ReceiveCategorySection(
                    availableIngredients: [dummyIngredient1, dummyIngredient2],
                    isRetail: false,
                    currency: 'с',
                    adapter: adapter,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField);
      expect(searchFieldFinder, findsOneWidget);
      expect(tester.widget<TextField>(searchFieldFinder).focusNode?.hasFocus, isTrue);

      // Снимаем фокус
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(searchFieldFinder).focusNode?.hasFocus, isFalse);

      // Эмулируем переключение таба на Витрину через переподачу виджета с обновленным isRetail
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<CategoryBloc>.value(
              value: catBloc,
              child: Column(
                children: [
                  ReceiveCategorySection(
                    availableIngredients: [dummyIngredient2],
                    isRetail: true,
                    currency: 'с',
                    adapter: adapter,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Фокус автоматически вернулся в поле поиска!
      expect(tester.widget<TextField>(searchFieldFinder).focusNode?.hasFocus, isTrue);
    });

    testWidgets('10. AppSaveShortcutScope вызывает onSearch при нажатии Ctrl+F в модалке', (tester) async {
      bool searchTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveShortcutScope(
              onSearch: () => searchTriggered = true,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Нажимаем Ctrl+F (PhysicalKeyboardKey.keyF)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(searchTriggered, isTrue);
    });

    testWidgets('11. Изоляция фонового поиска: при открытом диалоге фоновое поле не перехватывает Ctrl+F', (tester) async {
      final bgController = TextEditingController();
      final bgFocusNode = FocusNode();
      addTearDown(bgController.dispose);
      addTearDown(bgFocusNode.dispose);

      bool modalSearchCalled = false;

      await tester.pumpWidget(
        MaterialApp(
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
                          onSearch: () => modalSearchCalled = true,
                          child: const AlertDialog(title: Text('Модалка')),
                        ),
                      );
                    },
                    child: const Text('Открыть диалог'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Открываем модальный диалог
      await tester.tap(find.text('Открыть диалог'));
      await tester.pumpAndSettle();

      expect(find.text('Модалка'), findsOneWidget);

      // Нажимаем Ctrl+F
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Модалка перехватила Ctrl+F!
      expect(modalSearchCalled, isTrue);
      // Фоновый поиск НЕ сфокусировался
      expect(bgFocusNode.hasFocus, isFalse);
    });

    testWidgets('12. Курсор вне колонки: AppSaveShortcutScope перехватывает Ctrl+F и Esc при клике в фон модалки', (tester) async {
      final textController = TextEditingController();
      final textFocusNode = FocusNode();
      addTearDown(textController.dispose);
      addTearDown(textFocusNode.dispose);

      bool searchTriggered = false;
      bool cancelTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSaveShortcutScope(
              onSearch: () => searchTriggered = true,
              onCancel: () => cancelTriggered = true,
              child: Column(
                children: [
                  TextField(controller: textController, focusNode: textFocusNode),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Снимаем фокус с поля ввода
      textFocusNode.unfocus();
      await tester.pumpAndSettle();

      expect(textFocusNode.hasFocus, isFalse);

      // Нажимаем Ctrl+F вне колонки ввода
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, physicalKey: PhysicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(searchTriggered, isTrue);

      // Нажимаем Escape вне поля ввода -> вызывает onCancel
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(cancelTriggered, isTrue);
    });

    testWidgets('13. ReceiveDocumentAutocompleteField отображает выпадающий список без ошибок OverlayPortal', (tester) async {
      final rowItem = ReceiptRowData();
      addTearDown(rowItem.dispose);

      final ingredients = [
        Ingredient(id: 1, name: 'Кофе Зерновой', costPerUnit: 120.0, currentStock: 5.0, minStockAlert: 1.0, isLowStock: false, unit: 'кг'),
        Ingredient(id: 2, name: 'Молоко 3.2%', costPerUnit: 80.0, currentStock: -2.0, minStockAlert: 2.0, isLowStock: true, unit: 'л'),
      ];

      Ingredient? selectedIngredient;

      await tester.pumpWidget(
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(),
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  ReceiveDocumentAutocompleteField(
                    item: rowItem,
                    index: 0,
                    items: [rowItem],
                    availableIngredients: ingredients,
                    tabIndex: 0,
                    isDark: false,
                    onIngredientSelected: (sel) => selectedIngredient = sel,
                    onNameChanged: (_) {},
                    onNameSubmitted: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Вводим текст в поле
      rowItem.nameFocusNode.requestFocus();
      rowItem.nameController.text = 'Кофе';
      await tester.pumpAndSettle();

      // OverlayEntry отобразился
      expect(find.text('Кофе Зерновой'), findsOneWidget);

      // Нажимаем на позицию
      await tester.tap(find.text('Кофе Зерновой'));
      await tester.pumpAndSettle();

      expect(selectedIngredient?.name, 'Кофе Зерновой');
      // Оверлей закрылся
      expect(find.text('Закупка: 120'), findsNothing);
    });
  });
}
