import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';

class BulkAddListWidget extends StatelessWidget {
  final int tabIndex;
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
    required this.dishRows,
    required this.retailRows,
    required this.ingredientRows,
    required this.categoryRows,
    required this.onAddRow,
    required this.onDuplicateRow,
    required this.onRemoveRow,
  });

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
                  return _BulkRow(
                    index: index,
                    tabIndex: tabIndex,
                    dishRows: dishRows,
                    retailRows: retailRows,
                    ingredientRows: ingredientRows,
                    categoryRows: categoryRows,
                    onAddRow: onAddRow,
                    onDuplicate: () => onDuplicateRow(index),
                    onRemove: () => onRemoveRow(index),
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

class _BulkRow extends StatefulWidget {
  final int index;
  final int tabIndex;
  final List<DishRowData> dishRows;
  final List<RetailRowData> retailRows;
  final List<IngredientRowData> ingredientRows;
  final List<CategoryRowData> categoryRows;
  final VoidCallback onAddRow;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;

  const _BulkRow({
    required this.index,
    required this.tabIndex,
    required this.dishRows,
    required this.retailRows,
    required this.ingredientRows,
    required this.categoryRows,
    required this.onAddRow,
    required this.onDuplicate,
    required this.onRemove,
  });

  @override
  State<_BulkRow> createState() => _BulkRowState();
}

class _BulkRowState extends State<_BulkRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark
                  ? AppColors.darkBg.withValues(alpha: 0.8)
                  : AppColors.lightBg.withValues(alpha: 0.9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? AppColors.brandPrimary.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Номер строки
            SizedBox(
              width: 28,
              child: Text(
                '${widget.index + 1}.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
            // Виджет строки
            Expanded(
              child: widget.tabIndex == 0
                  ? DishRowWidget(
                      row: widget.dishRows[widget.index],
                      onAddRow: widget.onAddRow,
                    )
                  : (widget.tabIndex == 1
                      ? RetailRowWidget(
                          row: widget.retailRows[widget.index],
                          onAddRow: widget.onAddRow,
                        )
                      : (widget.tabIndex == 2
                          ? IngredientRowWidget(
                              row: widget.ingredientRows[widget.index],
                              onAddRow: widget.onAddRow,
                            )
                          : CategoryRowWidget(
                              row: widget.categoryRows[widget.index],
                              onAddRow: widget.onAddRow,
                            ))),
            ),
            // Иконки — всегда видны, но ярче при hover
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 150),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.copy,
                        color: AppColors.brandTertiary, size: 18),
                    onPressed: widget.onDuplicate,
                    tooltip: 'Дублировать',
                    splashRadius: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.trash,
                        color: AppColors.danger, size: 18),
                    onPressed: widget.onRemove,
                    tooltip: 'Удалить',
                    splashRadius: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


