import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';

class BulkAddRowItem extends StatefulWidget {
  final int index;
  final int tabIndex;
  final List<DishRowData> dishRows;
  final List<RetailRowData> retailRows;
  final List<IngredientRowData> ingredientRows;
  final List<CategoryRowData> categoryRows;
  final VoidCallback onAddRow;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback? onFocusPrevRow;
  final VoidCallback? onFocusNextRow;

  const BulkAddRowItem({
    super.key,
    required this.index,
    required this.tabIndex,
    required this.dishRows,
    required this.retailRows,
    required this.ingredientRows,
    required this.categoryRows,
    required this.onAddRow,
    required this.onDuplicate,
    required this.onRemove,
    this.onFocusPrevRow,
    this.onFocusNextRow,
  });

  @override
  State<BulkAddRowItem> createState() => _BulkAddRowItemState();
}

class _BulkAddRowItemState extends State<BulkAddRowItem> {
  late final ValueNotifier<bool> _isHovered;

  @override
  void initState() {
    super.initState();
    _isHovered = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isHovered.dispose();
    super.dispose();
  }

  Widget _buildRowWidget() {
    if (widget.tabIndex == 0) {
      return DishRowWidget(
        row: widget.dishRows[widget.index],
        onAddRow: widget.onAddRow,
        onFocusPrevRow: widget.onFocusPrevRow,
        onFocusNextRow: widget.onFocusNextRow,
      );
    } else if (widget.tabIndex == 1) {
      return RetailRowWidget(
        row: widget.retailRows[widget.index],
        onAddRow: widget.onAddRow,
        onFocusPrevRow: widget.onFocusPrevRow,
        onFocusNextRow: widget.onFocusNextRow,
      );
    } else if (widget.tabIndex == 2) {
      return IngredientRowWidget(
        row: widget.ingredientRows[widget.index],
        onAddRow: widget.onAddRow,
        onFocusPrevRow: widget.onFocusPrevRow,
        onFocusNextRow: widget.onFocusNextRow,
      );
    } else {
      return CategoryRowWidget(
        row: widget.categoryRows[widget.index],
        onAddRow: widget.onAddRow,
        onFocusPrevRow: widget.onFocusPrevRow,
        onFocusNextRow: widget.onFocusNextRow,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isHovered,
        builder: (context, hovered, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hovered
                  ? (isDark
                      ? AppColors.darkBg.withValues(alpha: 0.8)
                      : AppColors.lightBg.withValues(alpha: 0.9))
                  : AppColors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hovered
                    ? AppColors.brandPrimary.withValues(alpha: 0.2)
                    : AppColors.transparent,
              ),
            ),
            child: child,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Expanded(child: _buildRowWidget()),
            ValueListenableBuilder<bool>(
              valueListenable: _isHovered,
              builder: (context, hovered, _) {
                return AnimatedOpacity(
                  opacity: hovered ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.copy,
                          color: AppColors.brandTertiary,
                          size: 18,
                        ),
                        onPressed: widget.onDuplicate,
                        tooltip: 'Дублировать',
                        splashRadius: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          PhosphorIconsRegular.trash,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        onPressed: widget.onRemove,
                        tooltip: 'Удалить',
                        splashRadius: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
