// ==============================================================================
// МОДУЛЬ: Каталог / Дэшборд сводки техкарт и фудкоста (RecipeEmptyDashboard)
// ДОМЕН: lib/features/menu/view/widgets/catalog/recipe/recipe_empty_dashboard.dart
// ==============================================================================
//
// [ИНВАРИАНТ] Презентационный экран до выбора конкретного блюда: ключевые
// метрики покрытия меню техкартами на AppKpiCard и быстрый выбор блюда.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'recipe_quick_dish_tile.dart';

class RecipeEmptyDashboard extends StatelessWidget {
  final ValueChanged<int> onSelectDish;

  const RecipeEmptyDashboard({super.key, required this.onSelectDish});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuState = context.watch<MenuBloc>().state;
    final catState = context.watch<CategoryBloc>().state;

    // [ОПТИМИЗАЦИЯ] Селектор предотвращает лишние перерисовки при инлайн-мутациях
    final summaryMap = context.select<RecipeBloc, Map<int, Map<String, dynamic>>>(
      (b) => b.state.recipesSummary,
    );

    final activeCatMap = catState is CategoryLoaded
        ? {for (var c in catState.categories.where((c) => c.isVisible)) c.id.toString(): c}
        : <String, dynamic>{};

    final dishes = menuState is MenuLoaded
        ? menuState.items.where((i) {
            if (i.isRetail) return false;
            if (!i.isAvailable) return false;
            final catId = i.categoryId.toString();
            final isRoot = catId == '0' || catId == 'null' || catId == '' || catId == 'uncategorized';
            return isRoot || activeCatMap.containsKey(catId);
          }).toList()
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
          // ── Шапка дэшборда ──────────────────────────────────────────────────
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

          // ── KPI-стрип покрытия меню техкартами ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppKpiCard(
                  title: 'Всего блюд кухни',
                  value: '$totalDishes поз.',
                  icon: PhosphorIconsRegular.hamburger,
                  color: AppColors.brandPrimary,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppKpiCard(
                  title: 'С техкартой',
                  value: '$configuredCount готово',
                  icon: PhosphorIconsRegular.checkCircle,
                  color: AppColors.success,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppKpiCard(
                  title: 'Требуют техкарты',
                  value: unconfiguredCount > 0 ? '$unconfiguredCount без состава' : 'Все настроены',
                  icon: unconfiguredCount > 0 ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
                  color: unconfiguredCount > 0 ? AppColors.warning : AppColors.success,
                  compact: true,
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

          // ── Список быстрого выбора ──────────────────────────────────────────
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dish = dishes[index];
                      return RecipeQuickDishTile(
                        dish: dish,
                        summary: summaryMap[dish.id],
                        catState: catState,
                        onTap: () {
                          onSelectDish(dish.id);
                          context.read<RecipeBloc>().add(LoadRecipe(dish.id));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
