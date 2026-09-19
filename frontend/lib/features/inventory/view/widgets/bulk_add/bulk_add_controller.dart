import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';
import 'bulk_add_presets.dart';

class BulkAddController {
  final List<DishRowData> dishRows = [];
  final List<RetailRowData> retailRows = [];
  final List<IngredientRowData> ingredientRows = [];
  final List<CategoryRowData> categoryRows = [];

  void addRow(int tabIndex) {
    if (tabIndex == 0) {
      dishRows.add(DishRowData());
    } else if (tabIndex == 1) {
      final newRow = RetailRowData();
      if (retailRows.isNotEmpty) {
        newRow.selectedUnit = retailRows.last.selectedUnit;
      }
      retailRows.add(newRow);
    } else if (tabIndex == 2) {
      final newRow = IngredientRowData();
      if (ingredientRows.isNotEmpty) {
        newRow.selectedUnit = ingredientRows.last.selectedUnit;
      }
      ingredientRows.add(newRow);
    } else {
      categoryRows.add(CategoryRowData());
    }
  }

  FocusNode getLastFocusNode(int tabIndex) {
    return tabIndex == 0
        ? dishRows.last.firstFocusNode
        : (tabIndex == 1
            ? retailRows.last.firstFocusNode
            : (tabIndex == 2
                ? ingredientRows.last.firstFocusNode
                : categoryRows.last.firstFocusNode));
  }

  void duplicateRow(int tabIndex, int index) {
    if (tabIndex == 0) {
      dishRows.insert(index + 1, dishRows[index].clone());
    } else if (tabIndex == 1) {
      retailRows.insert(index + 1, retailRows[index].clone());
    } else if (tabIndex == 2) {
      ingredientRows.insert(index + 1, ingredientRows[index].clone());
    } else {
      categoryRows.insert(index + 1, categoryRows[index].clone());
    }
  }

  FocusNode getRowFocusNode(int tabIndex, int index) {
    return tabIndex == 0
        ? dishRows[index].firstFocusNode
        : (tabIndex == 1
            ? retailRows[index].firstFocusNode
            : (tabIndex == 2
                ? ingredientRows[index].firstFocusNode
                : categoryRows[index].firstFocusNode));
  }

  void removeRow(int tabIndex, int index) {
    if (tabIndex == 0) {
      dishRows.removeAt(index);
    } else if (tabIndex == 1) {
      retailRows.removeAt(index);
    } else if (tabIndex == 2) {
      ingredientRows.removeAt(index);
    } else {
      categoryRows.removeAt(index);
    }
  }

  void loadPreset({
    required BuildContext context,
    required int tabIndex,
    required String presetType,
    required String categoryType,
  }) {
    final catState = context.read<CategoryBloc>().state;
    final Map<String, int> catMap = {};
    if (catState is CategoryLoaded) {
      for (var c in catState.categories) {
        catMap[c.name.toLowerCase().trim()] = c.id;
      }
    }

    BulkAddPresets.loadPreset(
      tabIndex: tabIndex,
      presetType: presetType,
      categoryType: categoryType,
      catMap: catMap,
      dishRows: dishRows,
      retailRows: retailRows,
      ingredientRows: ingredientRows,
      categoryRows: categoryRows,
    );
  }

  void dispose() {
    for (var r in dishRows) {
      r.firstFocusNode.dispose();
    }
    for (var r in retailRows) {
      r.firstFocusNode.dispose();
    }
    for (var r in ingredientRows) {
      r.firstFocusNode.dispose();
    }
    for (var r in categoryRows) {
      r.firstFocusNode.dispose();
    }
  }
}
