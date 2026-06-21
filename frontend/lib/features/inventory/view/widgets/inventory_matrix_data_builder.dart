import 'package:pluto_grid/pluto_grid.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';

class InventoryMatrixDataBuilder {
  static List<PlutoColumn> buildColumns() {
    return [
      PlutoColumn(
        title: 'Название / Категория',
        field: 'name',
        type: PlutoColumnType.text(),
        width: 300,
        enableRowChecked: true,
      ),
      PlutoColumn(
        title: 'Тип',
        field: 'type',
        type: PlutoColumnType.select(['Категория', 'Сырье', 'Витрина']),
        width: 120,
      ),
      PlutoColumn(
        title: 'Ед. изм.',
        field: 'unit',
        type: PlutoColumnType.select(['', 'шт', 'кг', 'г', 'л', 'мл']),
        width: 100,
      ),
      PlutoColumn(
        title: 'Остаток',
        field: 'stock',
        type: PlutoColumnType.number(),
        width: 120,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Цена закупки (с)',
        field: 'cost',
        type: PlutoColumnType.number(),
        width: 150,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'Цена продажи (с)',
        field: 'retail_price',
        type: PlutoColumnType.number(),
        width: 150,
        textAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.text(),
        hide: true,
      ),
    ];
  }

  static List<PlutoRow> buildRows(
    CategoryState catState,
    IngredientState ingState,
    MenuState menuState,
  ) {
    if (catState is! CategoryLoaded ||
        ingState is! IngredientLoaded ||
        menuState is! MenuLoaded) {
      return [];
    }

    final categories = catState.categories;
    final ingredients = ingState.ingredients;
    final menuItems = menuState.items;

    List<PlutoRow> rows = [];
    Map<int, List<PlutoRow>> categoryChildren = {};

    for (var cat in categories) {
      categoryChildren[cat.id] = [];
    }

    for (var ing in ingredients) {
      final isRetail = ing.attributes?['is_retail'] == true;
      final typeStr = isRetail ? 'Витрина' : 'Сырье';
      final catId = ing.attributes?['category_id'] as int?;

      final row = PlutoRow(
        cells: {
          'name': PlutoCell(value: ing.name),
          'type': PlutoCell(value: typeStr),
          'unit': PlutoCell(value: ing.unit),
          'stock': PlutoCell(value: ing.currentStock),
          'cost': PlutoCell(value: ing.costPerUnit),
          'retail_price': PlutoCell(value: 0),
          'id': PlutoCell(value: 'ing_${ing.id}'),
        },
      );

      if (catId != null && categoryChildren.containsKey(catId)) {
        categoryChildren[catId]!.add(row);
      } else {
        rows.add(row);
      }
    }

    for (var item in menuItems) {
      final row = PlutoRow(
        cells: {
          'name': PlutoCell(value: item.name),
          'type': PlutoCell(value: 'Витрина'),
          'unit': PlutoCell(value: 'шт'),
          'stock': PlutoCell(value: 0),
          'cost': PlutoCell(value: 0),
          'retail_price': PlutoCell(value: item.price),
          'id': PlutoCell(value: 'menu_${item.id}'),
        },
      );

      final parsedCatId = int.tryParse(item.categoryId);
      if (parsedCatId != null && categoryChildren.containsKey(parsedCatId)) {
        categoryChildren[parsedCatId]!.add(row);
      } else {
        rows.add(row);
      }
    }

    for (var cat in categories) {
      if (cat.parentId == null) {
        rows.add(
          _buildCategoryRow(cat.id, cat.name, categories, categoryChildren),
        );
      }
    }

    return rows;
  }

  static PlutoRow _buildCategoryRow(
    int catId,
    String catName,
    List<dynamic> allCategories,
    Map<int, List<PlutoRow>> childrenMap,
  ) {
    List<PlutoRow> children = childrenMap[catId] ?? [];

    for (var subCat in allCategories) {
      if (subCat.parentId == catId) {
        children.add(
          _buildCategoryRow(subCat.id, subCat.name, allCategories, childrenMap),
        );
      }
    }

    return PlutoRow(
      type: PlutoRowType.group(
        children: FilteredList(initialList: children),
        expanded: true,
      ),
      cells: {
        'name': PlutoCell(value: catName),
        'type': PlutoCell(value: 'Категория'),
        'unit': PlutoCell(value: ''),
        'stock': PlutoCell(value: 0),
        'cost': PlutoCell(value: 0),
        'retail_price': PlutoCell(value: 0),
        'id': PlutoCell(value: 'cat_$catId'),
      },
    );
  }
}
