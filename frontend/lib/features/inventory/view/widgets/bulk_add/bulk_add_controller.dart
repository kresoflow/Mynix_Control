// ==============================================================================
// МОДУЛЬ: Склад / Контроллер массового добавления (Bulk Add Controller)
// ДОМЕН: lib/features/inventory/view/widgets/bulk_add/bulk_add_controller.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';
import 'bulk_add_presets.dart';

// ─── 1. Реактивный контроллер строк массового добавления ─────────────────────

/// Управляет строками ввода, фокусировкой и мгновенной синхронизацией
/// изменений полей для реактивной валидации коллизий дубликатов.
class BulkAddController extends ChangeNotifier {
  final List<DishRowData> dishRows = [];
  final List<RetailRowData> retailRows = [];
  final List<IngredientRowData> ingredientRows = [];
  final List<CategoryRowData> categoryRows = [];

  void _onAnyFieldChanged() {
    notifyListeners();
  }

  void _listenDish(DishRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
    row.nameController.addListener(_onAnyFieldChanged);
  }

  void _unlistenDish(DishRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
  }

  void _listenRetail(RetailRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
    row.flavorController.removeListener(_onAnyFieldChanged);
    row.volumeController.removeListener(_onAnyFieldChanged);
    row.barcodeController.removeListener(_onAnyFieldChanged);

    row.nameController.addListener(_onAnyFieldChanged);
    row.flavorController.addListener(_onAnyFieldChanged);
    row.volumeController.addListener(_onAnyFieldChanged);
    row.barcodeController.addListener(_onAnyFieldChanged);
  }

  void _unlistenRetail(RetailRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
    row.flavorController.removeListener(_onAnyFieldChanged);
    row.volumeController.removeListener(_onAnyFieldChanged);
    row.barcodeController.removeListener(_onAnyFieldChanged);
  }

  void _listenIngredient(IngredientRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
    row.nameController.addListener(_onAnyFieldChanged);
  }

  void _unlistenIngredient(IngredientRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
  }

  void _listenCategory(CategoryRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
    row.nameController.addListener(_onAnyFieldChanged);
  }

  void _unlistenCategory(CategoryRowData row) {
    row.nameController.removeListener(_onAnyFieldChanged);
  }

  void _listenAll() {
    for (final r in dishRows) {
      _listenDish(r);
    }
    for (final r in retailRows) {
      _listenRetail(r);
    }
    for (final r in ingredientRows) {
      _listenIngredient(r);
    }
    for (final r in categoryRows) {
      _listenCategory(r);
    }
  }

  void _unlistenAll() {
    for (final r in dishRows) {
      _unlistenDish(r);
    }
    for (final r in retailRows) {
      _unlistenRetail(r);
    }
    for (final r in ingredientRows) {
      _unlistenIngredient(r);
    }
    for (final r in categoryRows) {
      _unlistenCategory(r);
    }
  }

  void addRow(int tabIndex) {
    if (tabIndex == 0) {
      final newRow = DishRowData();
      _listenDish(newRow);
      dishRows.add(newRow);
    } else if (tabIndex == 1) {
      final newRow = RetailRowData();
      if (retailRows.isNotEmpty) {
        newRow.selectedUnit = retailRows.last.selectedUnit;
      }
      _listenRetail(newRow);
      retailRows.add(newRow);
    } else if (tabIndex == 2) {
      final newRow = IngredientRowData();
      if (ingredientRows.isNotEmpty) {
        newRow.selectedUnit = ingredientRows.last.selectedUnit;
      }
      _listenIngredient(newRow);
      ingredientRows.add(newRow);
    } else {
      final newRow = CategoryRowData();
      _listenCategory(newRow);
      categoryRows.add(newRow);
    }
    notifyListeners();
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
      final clone = dishRows[index].clone();
      _listenDish(clone);
      dishRows.insert(index + 1, clone);
    } else if (tabIndex == 1) {
      final clone = retailRows[index].clone();
      _listenRetail(clone);
      retailRows.insert(index + 1, clone);
    } else if (tabIndex == 2) {
      final clone = ingredientRows[index].clone();
      _listenIngredient(clone);
      ingredientRows.insert(index + 1, clone);
    } else {
      final clone = categoryRows[index].clone();
      _listenCategory(clone);
      categoryRows.insert(index + 1, clone);
    }
    notifyListeners();
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
      final removed = dishRows.removeAt(index);
      _unlistenDish(removed);
    } else if (tabIndex == 1) {
      final removed = retailRows.removeAt(index);
      _unlistenRetail(removed);
    } else if (tabIndex == 2) {
      final removed = ingredientRows.removeAt(index);
      _unlistenIngredient(removed);
    } else {
      final removed = categoryRows.removeAt(index);
      _unlistenCategory(removed);
    }
    notifyListeners();
  }

  void loadPreset({
    required BuildContext context,
    required int tabIndex,
    required String presetType,
    required String categoryType,
  }) {
    _unlistenAll();
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
    _listenAll();
    notifyListeners();
  }

  @override
  void dispose() {
    _unlistenAll();
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
    super.dispose();
  }
}
