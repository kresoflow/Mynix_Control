// ==============================================================================
// Title: CatalogSearchTest
// Path: frontend/test/catalog_search_test.dart
// Description: Модульные тесты фильтрации и изоляции поиска в каталоге меню.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_browser_actions.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';

void main() {
  group('CatalogBrowserActions Search Tests', () {
    late CategoryLoaded catState;
    late MenuLoaded menuState;

    setUp(() {
      final categories = [
        MenuCategory(id: 1, name: 'Шаурма', categoryType: 'dish', sortOrder: 1),
        MenuCategory(id: 2, name: 'Напитки', categoryType: 'dish', sortOrder: 2),
        MenuCategory(id: 3, name: 'Снэки', categoryType: 'retail', sortOrder: 1),
        MenuCategory(id: 4, name: 'Соусы к шаурме', categoryType: 'dish', sortOrder: 3, parentId: 1),
      ];

      final items = [
        const MenuItem(
          id: 101,
          name: 'Шаурма куриная',
          price: 250.0,
          categoryId: '1',
          sortOrder: 1,
        ),
        const MenuItem(
          id: 102,
          name: 'Шаурма говяжья',
          price: 300.0,
          categoryId: '1',
          sortOrder: 2,
        ),
        const MenuItem(
          id: 103,
          name: 'Кола 0.5',
          price: 100.0,
          categoryId: '2',
          sortOrder: 1,
        ),
        const MenuItem(
          id: 104,
          name: 'Чипсы со вкусом шаурмы',
          price: 120.0,
          categoryId: '3',
          sortOrder: 1,
        ),
      ];

      catState = CategoryLoaded(categories: categories);
      menuState = MenuLoaded(items: items);
    });

    test('На вкладке блюд (dish) при поиске папки категорий скрываются', () {
      // Ищем по запросу "шаур": папка "Шаурма" не должна попасть в выдачу на вкладке "Блюда"
      final categories = CatalogBrowserActions.filterCategories(
        catState: catState,
        categoryType: 'dish',
        showArchived: false,
        searchQuery: 'шаур',
        currentCategoryId: null,
      );

      expect(categories, isEmpty);
    });

    test('На вкладке витрины (retail) при поиске папки категорий скрываются', () {
      // Ищем по запросу "снэк": папки категорий не должны попадать в выдачу витрины
      final categories = CatalogBrowserActions.filterCategories(
        catState: catState,
        categoryType: 'retail',
        showArchived: false,
        searchQuery: 'снэк',
        currentCategoryId: null,
      );

      expect(categories, isEmpty);
    });

    test('На вкладке категорий (all) поиск возвращает подходящие категории', () {
      // На общей вкладке категорий поиск должен находить папки по имени
      final categories = CatalogBrowserActions.filterCategories(
        catState: catState,
        categoryType: 'all',
        showArchived: false,
        searchQuery: 'шаур',
        currentCategoryId: null,
      );

      expect(categories.length, equals(2));
      expect(categories.map((c) => c.name), containsAll(['Шаурма', 'Соусы к шаурме']));
    });

    test('При пустом поисковом запросе категории фильтруются по parentId', () {
      // В корневом каталоге должны отображаться только категории с parentId == null
      final rootCategories = CatalogBrowserActions.filterCategories(
        catState: catState,
        categoryType: 'dish',
        showArchived: false,
        searchQuery: '',
        currentCategoryId: null,
      );

      expect(rootCategories.length, equals(2));
      expect(rootCategories.map((c) => c.name), containsAll(['Шаурма', 'Напитки']));

      // Внутри категории 1 (Шаурма) должна отображаться подкатегория parentId == 1
      final subCategories = CatalogBrowserActions.filterCategories(
        catState: catState,
        categoryType: 'dish',
        showArchived: false,
        searchQuery: '',
        currentCategoryId: 1,
      );

      expect(subCategories.length, equals(1));
      expect(subCategories.first.name, equals('Соусы к шаурме'));
    });

    test('Поиск по блюдам находит все подходящие позиции независимо от категории', () {
      final items = CatalogBrowserActions.filterItems(
        menuState: menuState,
        showArchived: false,
        searchQuery: 'шаур',
        currentCategoryId: null,
        itemFilter: (item) => item.categoryId != '3', // фильтр блюд
      );

      expect(items.length, equals(2));
      expect(items.map((i) => i.name), containsAll(['Шаурма куриная', 'Шаурма говяжья']));
    });

    test('Поиск по витрине находит товары витрины', () {
      final items = CatalogBrowserActions.filterItems(
        menuState: menuState,
        showArchived: false,
        searchQuery: 'шаур',
        currentCategoryId: null,
        itemFilter: (item) => item.categoryId == '3', // фильтр витрины
      );

      expect(items.length, equals(1));
      expect(items.first.name, equals('Чипсы со вкусом шаурмы'));
    });
  });
}
