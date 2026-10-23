// ==============================================================================
// МОДУЛЬ: Справочник / Строка таблицы сырья (Ingredient Item Row)
// ДОМЕН: lib/features/menu/view/widgets/catalog/ingredient/ingredient_item_row.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'ingredient_row_actions.dart';

/// [UI-KIT] Стандартизированная строка таблицы сырья (AppDataTableRow)
class IngredientItemRow extends StatelessWidget {
  final Ingredient item;
  final List<AppDataTableColumn> columns;
  final String? categoryIcon;
  final String currency;
  final bool isManageMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  const IngredientItemRow({
    super.key,
    required this.item,
    required this.columns,
    required this.categoryIcon,
    required this.currency,
    required this.isManageMode,
    required this.isSelected,
    this.onSelect,
    required this.onEdit,
    required this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = item.isLowStock;
    final isCritical = item.currentStock <= 0;

    // ── Цветовая индикация остатка ──
    Color stockColor = AppColors.success;
    if (isCritical) {
      stockColor = AppColors.danger;
    } else if (isLowStock) {
      stockColor = AppColors.warning;
    }

    return AppDataTableRow(
      columns: columns,
      horizontalPadding: 16,
      minHeight: 48,
      isSelected: isSelected,
      onTap: isManageMode
          ? () => onSelect?.call(!isSelected)
          : onEdit,
      children: [
        // 0. Код или Чекбокс выбора
        isManageMode
            ? AppCheckbox(
                value: isSelected,
                size: AppCheckboxSize.md,
                onChanged: (val) => onSelect?.call(val),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBg,
                  borderRadius: AppRadii.radiusXs,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  item.displayCode,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),

        // 1. Наименование и Категория
        Row(
          children: [
            if (categoryIcon != null &&
                categoryIcon!.isNotEmpty &&
                (IconHelper.getIcon(categoryIcon) != null || categoryIcon!.startsWith('svg:')))
              Container(
                margin: const EdgeInsets.only(right: 10.0),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isLowStock ? AppColors.danger : AppColors.brandPrimary).withValues(alpha: 0.1),
                  borderRadius: AppRadii.badgeRadius,
                ),
                child: IconHelper.buildIcon(
                  categoryIcon,
                  color: isLowStock ? AppColors.danger : AppColors.brandPrimary,
                  size: 16,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: item.isArchived ? TextDecoration.lineThrough : null,
                            color: item.isArchived
                                ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                                : (isDark ? AppColors.darkText : AppColors.lightText),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isArchived) ...[
                        const SizedBox(width: 6),
                        const AppStatusBadge(
                          label: 'В архиве',
                          variant: AppBadgeVariant.neutral,
                          height: 18,
                        ),
                      ] else if (item.categoryId == null) ...[
                        const SizedBox(width: 6),
                        const AppStatusBadge(
                          label: 'Без категории',
                          variant: AppBadgeVariant.warning,
                          height: 18,
                        ),
                      ],
                    ],
                  ),
                  if (item.categoryName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.categoryName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        // 2. Текущий остаток
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              UnitFormatter.formatAmount(item.currentStock, item.unit),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: stockColor,
              ),
            ),
          ],
        ),

        // 3. Минимальный запас (Алерт)
        Text(
          item.minStockAlert > 0
              ? UnitFormatter.formatAmount(item.minStockAlert, item.unit)
              : '—',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),

        // 4. Себестоимость
        Text(
          '${item.costPerUnit.toStringAsFixed(2)} $currency / ${UnitFormatter.format(item.unit)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),

        // 5. Меню действий
        if (!isManageMode)
          IngredientRowActions(
            item: item,
            onEdit: onEdit,
            onDelete: onDelete,
            onRestore: onRestore,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
