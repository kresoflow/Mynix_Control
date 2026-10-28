// ==============================================================================
// МОДУЛЬ: Склад / Строка массового добавления (Bulk Add Row Item)
// ДОМЕН: lib/features/inventory/view/widgets/bulk_add/bulk_add_row_item.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'bulk_add_controller.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';
import 'bulk_add_duplicate_validator.dart';

// ─── 1. Виджет строки массового ввода ─────────────────────────────────────────

/// Индивидуальная строка таблицы массового ввода с поддержкой дублирования,
/// удаления, навигации стрелками и мгновенной реактивной проверки на коллизии дубликатов.
class BulkAddRowItem extends StatefulWidget {
  final int index;
  final int tabIndex;
  final BulkAddController controller;
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
    required this.controller,
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
    widget.controller.addListener(_onBatchChanged);
  }

  @override
  void didUpdateWidget(BulkAddRowItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onBatchChanged);
      widget.controller.addListener(_onBatchChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onBatchChanged);
    _isHovered.dispose();
    super.dispose();
  }

  void _onBatchChanged() {
    if (mounted) setState(() {});
  }

  bool get _isOutOfBounds {
    if (widget.tabIndex == 0) return widget.index >= widget.dishRows.length;
    if (widget.tabIndex == 1) return widget.index >= widget.retailRows.length;
    if (widget.tabIndex == 2) return widget.index >= widget.ingredientRows.length;
    if (widget.tabIndex == 3) return widget.index >= widget.categoryRows.length;
    return true;
  }

  Widget _buildRowWidget() {
    if (_isOutOfBounds) return const SizedBox.shrink();
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
    if (_isOutOfBounds) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dupWarning = BulkAddDuplicateValidator.checkDuplicate(
      context: context,
      tabIndex: widget.tabIndex,
      index: widget.index,
      dishRows: widget.dishRows,
      retailRows: widget.retailRows,
      ingredientRows: widget.ingredientRows,
      categoryRows: widget.categoryRows,
    );

    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isHovered,
        builder: (context, hovered, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: dupWarning != null
                  ? AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.08)
                  : hovered
                      ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                      : AppColors.transparent,
              borderRadius: AppRadii.inputRadius,
              border: Border.all(
                color: dupWarning != null
                    ? AppColors.warning.withValues(alpha: isDark ? 0.4 : 0.6)
                    : hovered
                        ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                        : AppColors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                    Expanded(child: _buildRowWidget()),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(PhosphorIconsRegular.copy, size: 16, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                            tooltip: 'Дублировать',
                            visualDensity: VisualDensity.compact,
                            splashRadius: 16,
                            onPressed: widget.onDuplicate,
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.error),
                            tooltip: 'Удалить',
                            visualDensity: VisualDensity.compact,
                            splashRadius: 16,
                            onPressed: widget.onRemove,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (dupWarning != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.warningCircle, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          dupWarning,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.warning : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
