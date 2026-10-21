// ==============================================================================
// МОДУЛЬ: Справочник / Строка таблицы сырья (Ingredient Item Row)
// ДОМЕН: lib/features/menu/view/widgets/catalog/ingredient/ingredient_item_row.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'ingredient_row_actions.dart';

/// [UI-KIT] Интерактивная строка сырья в каталоге на базе дизайн-системы Kreso Flow
class IngredientItemRow extends StatefulWidget {
  final Ingredient item;
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
  State<IngredientItemRow> createState() => _IngredientItemRowState();
}

class _IngredientItemRowState extends State<IngredientItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;
    final isLowStock = item.isLowStock;
    final isCritical = item.currentStock <= 0;

    // ── Цветовая индикация остатка ──
    Color stockColor = AppColors.success;
    if (isCritical) {
      stockColor = AppColors.danger;
    } else if (isLowStock) {
      stockColor = AppColors.warning;
    }

    Color bg;
    if (widget.isSelected) {
      bg = AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10);
    } else if (_isHovered) {
      bg = isDark ? AppColors.darkCardHover : AppColors.lightBg;
    } else {
      bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isManageMode ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standardCurve,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isManageMode ? () => widget.onSelect?.call(!widget.isSelected) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Управление: AppCheckbox ИЛИ Иконка категории
                  if (widget.isManageMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 14.0),
                      child: AppCheckbox(
                        value: widget.isSelected,
                        size: AppCheckboxSize.md,
                        onChanged: (val) => widget.onSelect?.call(val),
                      ),
                    )
                  else if (widget.categoryIcon != null &&
                      widget.categoryIcon!.isNotEmpty &&
                      (IconHelper.getIcon(widget.categoryIcon) != null || widget.categoryIcon!.startsWith('svg:')))
                    Container(
                      margin: const EdgeInsets.only(right: 14.0),
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (isLowStock ? AppColors.danger : AppColors.brandPrimary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: (isLowStock ? AppColors.danger : AppColors.brandPrimary).withValues(alpha: 0.25),
                        ),
                      ),
                      child: IconHelper.buildIcon(
                        widget.categoryIcon,
                        color: isLowStock ? AppColors.danger : AppColors.brandPrimary,
                        size: 20,
                      ),
                    ),

                  // 2. Название, код и статус
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightBg,
                                borderRadius: BorderRadius.circular(AppRadii.xs),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Text(
                                item.displayCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: item.isArchived ? TextDecoration.lineThrough : null,
                                  color: item.isArchived
                                      ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                                      : (isDark ? AppColors.darkText : AppColors.lightText),
                                ),
                              ),
                            ),
                            if (item.isArchived) ...[
                              const SizedBox(width: 8),
                              const AppStatusBadge(
                                label: 'В архиве',
                                variant: AppBadgeVariant.neutral,
                                height: 20,
                              ),
                            ] else if (item.categoryId == null) ...[
                              const SizedBox(width: 8),
                              const AppStatusBadge(
                                label: 'Без категории',
                                variant: AppBadgeVariant.warning,
                                height: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.categoryName ?? 'Без категории',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Остаток и алерт
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              UnitFormatter.formatAmount(item.currentStock, item.unit),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: stockColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            'Алерт: ${UnitFormatter.formatAmount(item.minStockAlert, item.unit)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Финансы и действия
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.costPerUnit.toStringAsFixed(2)} ${widget.currency}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'за 1 ${UnitFormatter.format(item.unit)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                        if (!widget.isManageMode)
                          IngredientRowActions(
                            item: item,
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            onRestore: widget.onRestore,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
