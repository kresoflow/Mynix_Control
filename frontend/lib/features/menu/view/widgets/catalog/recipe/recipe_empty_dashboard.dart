import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';

class RecipeEmptyDashboard extends StatelessWidget {
  final ValueChanged<int> onSelectDish;

  const RecipeEmptyDashboard({super.key, required this.onSelectDish});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuState = context.watch<MenuBloc>().state;
    final catState = context.watch<CategoryBloc>().state;
    final recipeState = context.watch<RecipeBloc>().state;
    final summaryMap = recipeState.recipesSummary;

    final dishes = menuState is MenuLoaded 
        ? menuState.items.where((i) => !i.isRetail).toList() 
        : [];

    final int totalDishes = dishes.length;
    int configuredCount = 0;
    for (final d in dishes) {
      if (summaryMap[d.id]?['has_recipe'] == true) {
        configuredCount++;
      }
    }
    final int unconfiguredCount = totalDishes - configuredCount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIconsRegular.chartLineUp,
                  color: AppColors.brandPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Центр управления техкартами и фудкостом',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Выберите блюдо слева для настройки калькуляции и списания сырья',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // KPI Summary Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Всего блюд кухни',
                  value: '$totalDishes поз.',
                  icon: PhosphorIconsRegular.hamburger,
                  color: AppColors.brandPrimary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'С техкартой',
                  value: '$configuredCount готово',
                  icon: PhosphorIconsRegular.checkCircle,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Требуют техкарты',
                  value: unconfiguredCount > 0 ? '$unconfiguredCount без состава' : 'Все настроены',
                  icon: unconfiguredCount > 0 ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
                  color: unconfiguredCount > 0 ? AppColors.warning : AppColors.success,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Быстрый выбор блюда для настройки:',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),

          // Quick selection list
          Expanded(
            child: dishes.isEmpty
                ? Center(
                    child: Text(
                      'В меню пока нет блюд',
                      style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    ),
                  )
                : ListView.separated(
                    itemCount: dishes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dish = dishes[index];
                      final summary = summaryMap[dish.id];
                      final bool hasRecipe = summary?['has_recipe'] == true;
                      final double cost = (summary?['total_cost'] as num?)?.toDouble() ?? 0.0;
                      final double marginPercent = dish.price > 0 && cost > 0
                          ? ((dish.price - cost) / dish.price) * 100
                          : 0.0;

                      // Dynamic Icon resolution
                      String? iconStr = dish.icon;
                      if ((iconStr == null || iconStr.isEmpty) && catState is CategoryLoaded) {
                        final cat = catState.categories.where((c) => c.id.toString() == dish.categoryId).firstOrNull;
                        iconStr = cat?.getInheritedIcon(catState.categories);
                      }

                      final bool hasIcon = iconStr != null &&
                          iconStr.isNotEmpty &&
                          (IconHelper.getIcon(iconStr) != null || iconStr.startsWith('svg:'));

                      return Material(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            onSelectDish(dish.id);
                            context.read<RecipeBloc>().add(LoadRecipe(dish.id));
                          },
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark ? AppColors.darkText : AppColors.lightText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            dish.categoryName ?? 'Без категории',
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
                                                color: AppColors.success.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Себестоимость: ${cost.toStringAsFixed(0)} с (${marginPercent.toStringAsFixed(0)}% маржа)',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '⚠️ Требуется состав',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.warning,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${dish.price.toStringAsFixed(0)} с',
                                  style: TextStyle(
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
