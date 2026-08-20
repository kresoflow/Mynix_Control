import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';

class BulkAddPresets {
  static void loadPreset({
    required int tabIndex,
    required String presetType,
    required String categoryType,
    required Map<String, int> catMap,
    required List<DishRowData> dishRows,
    required List<RetailRowData> retailRows,
    required List<IngredientRowData> ingredientRows,
    required List<CategoryRowData> categoryRows,
  }) {
    if (tabIndex == 3) {
      _loadCategoryPreset(presetType, categoryType, categoryRows);
    } else if (tabIndex == 2) {
      _loadIngredientPreset(presetType, catMap, ingredientRows);
    } else if (tabIndex == 1) {
      _loadRetailPreset(catMap, retailRows);
    } else if (tabIndex == 0) {
      _loadDishPreset(presetType, catMap, dishRows);
    }
  }

  static void _loadCategoryPreset(String presetType, String categoryType, List<CategoryRowData> categoryRows) {
    List<Map<String, String>> preset = [];
    if (categoryType == 'dish') {
      preset = presetType == 'fastfood'
          ? [
              {'name': 'Бургеры', 'icon': 'burger'},
              {'name': 'Закуски и Фри', 'icon': 'frenchFries'},
              {'name': 'Напитки', 'icon': 'cup'},
              {'name': 'Десерты', 'icon': 'cookie'},
              {'name': 'Соусы', 'icon': 'drop'},
            ]
          : [
              {'name': 'Горячие блюда', 'icon': 'cookingPot'},
              {'name': 'Паста и пицца', 'icon': 'pizza'},
              {'name': 'Салаты', 'icon': 'plant'},
              {'name': 'Супы', 'icon': 'bowl'},
              {'name': 'Закуски', 'icon': 'frenchFries'},
              {'name': 'Десерты', 'icon': 'cookie'},
              {'name': 'Бар и напитки', 'icon': 'beer'},
            ];
    } else if (categoryType == 'retail') {
      preset = [
        {'name': 'Бутилированные напитки', 'icon': 'cup'},
        {'name': 'Снэки и чипсы', 'icon': 'package'},
        {'name': 'Шоколад и батончики', 'icon': 'cookie'},
        {'name': 'Жвачки и леденцы', 'icon': 'drop'},
      ];
    } else {
      preset = presetType == 'fastfood'
          ? [
              {'name': 'Мясо и полуфабрикаты', 'icon': 'meat'},
              {'name': 'Хлеб и выпечка', 'icon': 'bread'},
              {'name': 'Молочка и сыры', 'icon': 'cheese'},
              {'name': 'Соусы и приправы', 'icon': 'drop'},
              {'name': 'Овощи и зелень', 'icon': 'plant'},
              {'name': 'Заморозка', 'icon': 'snowflake'},
              {'name': 'Масла и жиры', 'icon': 'dropHalf'},
              {'name': 'Упаковка и расходники', 'icon': 'package'},
            ]
          : [
              {'name': 'Мясо и полуфабрикаты', 'icon': 'meat'},
              {'name': 'Хлеб и выпечка', 'icon': 'bread'},
              {'name': 'Молочка и сыры', 'icon': 'cheese'},
              {'name': 'Соусы и приправы', 'icon': 'drop'},
              {'name': 'Овощи и зелень', 'icon': 'plant'},
              {'name': 'Заморозка', 'icon': 'snowflake'},
              {'name': 'Масла и жиры', 'icon': 'dropHalf'},
              {'name': 'Упаковка и расходники', 'icon': 'package'},
              {'name': 'Рыба и морепродукты', 'icon': 'fishSimple'},
              {'name': 'Крупы и макароны', 'icon': 'grains'},
              {'name': 'Напитки', 'icon': 'beer'},
              {'name': 'Десертные ингредиенты', 'icon': 'cookie'},
            ];
    }

    categoryRows.clear();
    for (int i = 0; i < preset.length; i++) {
      final row = CategoryRowData();
      row.nameController.text = preset[i]['name']!;
      row.selectedIcon = preset[i]['icon'];
      row.sortOrderController.text = (i + 1).toString();
      categoryRows.add(row);
    }
  }

  static void _loadIngredientPreset(String presetType, Map<String, int> catMap, List<IngredientRowData> ingredientRows) {
    final List<Map<String, dynamic>> preset = presetType == 'fastfood'
        ? [
            {'name': 'Говяжья котлета (п/ф 150г)', 'unit': 'pcs', 'cost': 85.0, 'alert': 20.0, 'category': 'Мясо и полуфабрикаты', 'sku': '10-01'},
            {'name': 'Булочка Бриошь с кунжутом', 'unit': 'pcs', 'cost': 25.0, 'alert': 30.0, 'category': 'Хлеб и выпечка', 'sku': '20-01'},
            {'name': 'Сыр Чеддер (слайсы)', 'unit': 'kg', 'cost': 650.0, 'alert': 2.0, 'category': 'Молочка и сыры', 'sku': '30-01'},
            {'name': 'Соус «Бургер Smoke»', 'unit': 'kg', 'cost': 220.0, 'alert': 3.0, 'category': 'Соусы и приправы', 'sku': '40-01'},
            {'name': 'Огурцы маринованные (слайсы)', 'unit': 'kg', 'cost': 180.0, 'alert': 1.5, 'category': 'Овощи и зелень', 'sku': '50-01'},
            {'name': 'Помидоры свежие', 'unit': 'kg', 'cost': 120.0, 'alert': 5.0, 'category': 'Овощи и зелень', 'sku': '50-02'},
            {'name': 'Картофель фри (заморозка 9мм)', 'unit': 'kg', 'cost': 140.0, 'alert': 15.0, 'category': 'Заморозка', 'sku': '60-01'},
            {'name': 'Масло фритюрное', 'unit': 'l', 'cost': 130.0, 'alert': 10.0, 'category': 'Масла и жиры', 'sku': '70-01'},
            {'name': 'Соль пищевая поваренная', 'unit': 'kg', 'cost': 30.0, 'alert': 1.0, 'category': 'Соусы и приправы', 'sku': '40-02'},
            {'name': 'Упаковка для бургера крафт', 'unit': 'pcs', 'cost': 4.5, 'alert': 100.0, 'category': 'Упаковка и расходники', 'sku': '80-01'},
          ]
        : [
            {'name': 'Стейк Рибай п/ф 300г', 'unit': 'pcs', 'cost': 550.0, 'alert': 10.0, 'category': 'Мясо и полуфабрикаты', 'sku': '10-01'},
            {'name': 'Лосось свежий филе', 'unit': 'kg', 'cost': 1200.0, 'alert': 5.0, 'category': 'Рыба и морепродукты', 'sku': '90-01'},
            {'name': 'Сливки 33%', 'unit': 'l', 'cost': 380.0, 'alert': 8.0, 'category': 'Молочка и сыры', 'sku': '30-01'},
            {'name': 'Сыр Пармезан', 'unit': 'kg', 'cost': 1400.0, 'alert': 3.0, 'category': 'Молочка и сыры', 'sku': '30-02'},
            {'name': 'Паста Феттуччине', 'unit': 'kg', 'cost': 220.0, 'alert': 10.0, 'category': 'Крупы и макароны', 'sku': '11-01'},
            {'name': 'Оливковое масло Extra Virgin', 'unit': 'l', 'cost': 750.0, 'alert': 5.0, 'category': 'Масла и жиры', 'sku': '70-01'},
            {'name': 'Томаты Черри', 'unit': 'kg', 'cost': 250.0, 'alert': 4.0, 'category': 'Овощи и зелень', 'sku': '50-01'},
            {'name': 'Зелень микс (руккола, шпинат)', 'unit': 'kg', 'cost': 450.0, 'alert': 3.0, 'category': 'Овощи и зелень', 'sku': '50-02'},
          ];

    ingredientRows.clear();
    for (var item in preset) {
      final catName = item['category'] as String?;
      final row = IngredientRowData(
        categoryId: catName != null ? catMap[catName.toLowerCase().trim()] : null,
        categoryName: catName,
        sku: item['sku'] as String?,
      );
      row.nameController.text = item['name'] as String;
      row.selectedUnit = item['unit'] as String;
      row.costController.text = (item['cost'] as num).toString();
      row.alertController.text = (item['alert'] as num).toString();
      ingredientRows.add(row);
    }
  }

  static void _loadRetailPreset(Map<String, int> catMap, List<RetailRowData> retailRows) {
    final List<Map<String, dynamic>> preset = [
      {'name': 'Coca-Cola Classic 0.5л (ПЭТ)', 'sell': 75.0, 'purchase': 42.0, 'stock': 24.0, 'alert': 12.0, 'barcode': '5449000000996', 'category': 'Бутилированные напитки'},
      {'name': 'Fanta Orange 0.5л (ПЭТ)', 'sell': 75.0, 'purchase': 42.0, 'stock': 24.0, 'alert': 12.0, 'barcode': '5449000011527', 'category': 'Бутилированные напитки'},
      {'name': 'Sprite 0.5л (ПЭТ)', 'sell': 75.0, 'purchase': 42.0, 'stock': 24.0, 'alert': 12.0, 'barcode': '5449000011558', 'category': 'Бутилированные напитки'},
      {'name': 'Вода Bonaqua 0.5л', 'sell': 50.0, 'purchase': 25.0, 'stock': 30.0, 'alert': 15.0, 'barcode': '5449000131805', 'category': 'Бутилированные напитки'},
      {'name': 'Чипсы Lays с солью 80г', 'sell': 120.0, 'purchase': 75.0, 'stock': 20.0, 'alert': 10.0, 'barcode': '4600648011234', 'category': 'Снэки и чипсы'},
    ];

    retailRows.clear();
    for (var item in preset) {
      final catName = item['category'] as String?;
      final row = RetailRowData(
        categoryId: catName != null ? catMap[catName.toLowerCase().trim()] : null,
        categoryName: catName,
      );
      row.nameController.text = item['name'] as String;
      row.purchaseController.text = (item['purchase'] as num).toString();
      row.sellController.text = (item['sell'] as num).toString();
      row.stockController.text = (item['stock'] as num).toString();
      row.alertController.text = (item['alert'] as num).toString();
      row.barcodeController.text = (item['barcode'] as String?) ?? '';
      retailRows.add(row);
    }
  }

  static void _loadDishPreset(String presetType, Map<String, int> catMap, List<DishRowData> dishRows) {
    final List<Map<String, dynamic>> preset = presetType == 'fastfood'
        ? [
            {'name': 'Кранчи Чизбургер', 'price': 290.0, 'options': 'Стандарт, Двойной сыр', 'prices': '290, 325', 'category': 'Бургеры'},
            {'name': 'Бургер Классический', 'price': 260.0, 'options': '', 'prices': '', 'category': 'Бургеры'},
            {'name': 'Картофель Фри Стандарт', 'price': 130.0, 'options': 'Стандарт, Большой', 'prices': '130, 180', 'category': 'Закуски и Фри'},
            {'name': 'Наггетсы хрустящие', 'price': 180.0, 'options': '6 шт, 9 шт', 'prices': '180, 250', 'category': 'Закуски и Фри'},
            {'name': 'Coca-Cola Разливная 0.5л', 'price': 75.0, 'options': '', 'prices': '', 'category': 'Напитки'},
          ]
        : [
            {'name': 'Паста Карбонара', 'price': 450.0, 'options': '', 'prices': '', 'category': 'Горячие блюда'},
            {'name': 'Стейк Рибай', 'price': 1200.0, 'options': 'Medium, Well Done', 'prices': '1200, 1200', 'category': 'Горячие блюда'},
            {'name': 'Салат Цезарь с курицей', 'price': 390.0, 'options': '', 'prices': '', 'category': 'Салаты'},
            {'name': 'Суп Том Ям с морепродуктами', 'price': 490.0, 'options': '', 'prices': '', 'category': 'Супы'},
          ];

    dishRows.clear();
    for (var item in preset) {
      final catName = item['category'] as String?;
      final row = DishRowData(
        categoryId: catName != null ? catMap[catName.toLowerCase().trim()] : null,
        categoryName: catName,
      );
      row.nameController.text = item['name'] as String;
      row.priceController.text = (item['prices'] as String).isNotEmpty ? (item['prices'] as String) : (item['price'] as num).toString();
      row.optionsController.text = item['options'] as String;
      dishRows.add(row);
    }
  }
}
