// ==============================================================================
// МОДУЛЬ: Каталог / Плитка быстрого выбора блюда на стартовом дэшборде техкарт
// ДОМЕН: lib/features/menu/view/widgets/catalog/recipe/recipe_quick_dish_tile.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';

class RecipeQuickDishTile extends StatelessWidget {
  final dynamic dish;
  final Map<String, dynamic>? summary;
  final CategoryState catState;
  final VoidCallback onTap;

  const RecipeQuickDishTile({
    super.key,
    required this.dish,
    required this.summary,
    required this.catState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasRecipe = summary?['has_recipe'] == true;
    final double cost = (summary?['total_cost'] as num?)?.toDouble() ?? 0.0;
    final double marginPercent = dish.price > 0 && cost > 0
        ? ((dish.price - cost) / dish.price) * 100
        : 0.0;

    String? categoryName = dish.categoryName;
    String? iconStr = dish.icon;
    if (catState is CategoryLoaded) {
      final loaded = catState as CategoryLoaded;
      final cat = loaded.categories.where((c) => c.id.toString() == dish.categoryId).firstOrNull;
      if (iconStr == null || iconStr.isEmpty) {
        iconStr = cat?.getInheritedIcon(loaded.categories);
      }
      if (categoryName == null || categoryName.isEmpty) {
        categoryName = cat?.name;
      }
    }

    final bool hasIcon = iconStr != null &&
        iconStr.isNotEmpty &&
        (IconHelper.getIcon(iconStr) != null || iconStr.startsWith('svg:'));

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (hasIcon) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: IconHelper.buildIcon(
                    iconStr,
                    size: 16,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.cleanName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          categoryName ?? 'Без категории',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasRecipe)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: (marginPercent >= 0 ? AppColors.success : AppColors.danger)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Себестоимость: ${cost.toStringAsFixed(0)} с (${marginPercent.toStringAsFixed(0)}% маржа)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: marginPercent >= 0 ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIconsBold.warningCircle, size: 11, color: AppColors.warning),
                                SizedBox(width: 4),
                                Text(
                                  'Требуется состав',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${dish.price.toStringAsFixed(0)} с',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
