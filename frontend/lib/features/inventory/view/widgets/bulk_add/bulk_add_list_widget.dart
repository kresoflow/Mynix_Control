// ==============================================================================
// МОДУЛЬ: Склад / Список строк массового добавления (Bulk Add List Widget)
// ДОМЕН: lib/features/inventory/view/widgets/bulk_add/bulk_add_list_widget.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'bulk_add_controller.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';
import 'bulk_add_row_item.dart';

// ─── 1. Виджет скроллируемого списка строк массового ввода ───────────────────

class BulkAddListWidget extends StatelessWidget {
  final int tabIndex;
  final BulkAddController controller;
  final List<DishRowData> dishRows;
  final List<RetailRowData> retailRows;
  final List<IngredientRowData> ingredientRows;
  final List<CategoryRowData> categoryRows;
  final VoidCallback onAddRow;
  final void Function(int) onDuplicateRow;
  final void Function(int) onRemoveRow;

  const BulkAddListWidget({
    super.key,
    required this.tabIndex,
    required this.controller,
    required this.dishRows,
    required this.retailRows,
    required this.ingredientRows,
    required this.categoryRows,
    required this.onAddRow,
    required this.onDuplicateRow,
    required this.onRemoveRow,
  });

  void _focusRowIndex(int i) {
    if (tabIndex == 0 && i >= 0 && i < dishRows.length) {
      dishRows[i].firstFocusNode.requestFocus();
    } else if (tabIndex == 1 && i >= 0 && i < retailRows.length) {
      retailRows[i].firstFocusNode.requestFocus();
    } else if (tabIndex == 2 && i >= 0 && i < ingredientRows.length) {
      ingredientRows[i].firstFocusNode.requestFocus();
    } else if (tabIndex == 3 && i >= 0 && i < categoryRows.length) {
      categoryRows[i].firstFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = tabIndex == 0
        ? dishRows.length
        : (tabIndex == 1
            ? retailRows.length
            : (tabIndex == 2 ? ingredientRows.length : categoryRows.length));

    return LayoutBuilder(
      builder: (context, constraints) {
        double minWidth = constraints.maxWidth;
        if (tabIndex == 1) {
          minWidth = 1000.0;
        } else if (tabIndex == 0) {
          minWidth = 800.0;
        } else if (tabIndex == 2) {
          minWidth = 1000.0;
        }

        final targetWidth = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;

        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: targetWidth,
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final rowId = tabIndex == 0
                      ? dishRows[index].id
                      : (tabIndex == 1
                          ? retailRows[index].id
                          : (tabIndex == 2
                              ? ingredientRows[index].id
                              : categoryRows[index].id));

                  return RepaintBoundary(
                    key: ValueKey(rowId),
                    child: BulkAddRowItem(
                      key: ValueKey(rowId),
                      index: index,
                      tabIndex: tabIndex,
                      controller: controller,
                      dishRows: dishRows,
                      retailRows: retailRows,
                      ingredientRows: ingredientRows,
                      categoryRows: categoryRows,
                      onAddRow: onAddRow,
                      onDuplicate: () => onDuplicateRow(index),
                      onRemove: () => onRemoveRow(index),
                      onFocusPrevRow: index > 0 ? () => _focusRowIndex(index - 1) : null,
                      onFocusNextRow: index < itemCount - 1 ? () => _focusRowIndex(index + 1) : null,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
