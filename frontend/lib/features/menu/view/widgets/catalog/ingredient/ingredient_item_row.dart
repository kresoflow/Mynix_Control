import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IngredientItemRow extends StatelessWidget {
  final Ingredient item;
  final String? categoryIcon;
  final String currency;
  final bool isManageMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = item.isLowStock;
    final isCritical = item.currentStock <= 0;

    // Индикатор остатка
    Color stockColor = AppColors.success;
    if (isCritical) {
      stockColor = AppColors.danger;
    } else if (isLowStock) {
      stockColor = AppColors.warning;
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.brandPrimary.withValues(alpha: 0.1) 
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isManageMode
              ? () => onSelect?.call(!isSelected)
              : () {
                  // Открыть детали (future feature)
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Управление: Чекбокс ИЛИ Иконка категории
                if (isManageMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onSelect,
                      activeColor: AppColors.brandPrimary,
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isLowStock ? AppColors.danger : AppColors.brandPrimary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconHelper.buildIcon(
                      categoryIcon,
                      color: isLowStock ? AppColors.danger : AppColors.brandPrimary,
                      size: 24,
                    ),
                  ),

                // Название
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.categoryName ?? 'Без категории',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),

                // Остаток и Алерт
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: stockColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          'Алерт: ${item.minStockAlert.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Финансы и действия
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.costPerUnit.toStringAsFixed(2)} $currency',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'за 1 ${item.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                        ],
                      ),
                      if (!isManageMode) ...[
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(
                            PhosphorIconsRegular.dotsThreeVertical,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                          onSelected: (val) {
                            if (val == 'edit') onEdit();
                            if (val == 'delete') onDelete();
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                            PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.danger))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
