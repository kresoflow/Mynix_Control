// ==============================================================================
// Title: IngredientGridView
// Path: frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_grid_view.dart
// Description: Сеточное отображение каталога сырья и заготовок.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_grid_card.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

// [UI-KIT] Сетка карточек сырья с фильтрацией по дереву категорий
class IngredientGridView extends StatelessWidget {
  final List<Ingredient> ingredients;
  final int? selectedCategoryId;
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final Function(int id, bool selected) onToggleSelect;

  const IngredientGridView({
    super.key,
    required this.ingredients,
    required this.selectedCategoryId,
    required this.isManageMode,
    required this.selectedIngredients,
    required this.onToggleSelect,
  });

  Set<int> _getCategoryAndSubcategories(int parentId, List<MenuCategory> allCategories) {
    final result = {parentId};
    final toCheck = [parentId];
    while (toCheck.isNotEmpty) {
      final current = toCheck.removeLast();
      final children = allCategories.where((c) => c.parentId == current).map((c) => c.id).toList();
      result.addAll(children);
      toCheck.addAll(children);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catState = context.watch<CategoryBloc>().state;
    List<MenuCategory> allCategories = [];
    if (catState is CategoryLoaded) {
      allCategories = catState.categories;
    }

    final validCategoryIds = selectedCategoryId == null
        ? null
        : _getCategoryAndSubcategories(selectedCategoryId!, allCategories);

    final rawIngredients = ingredients.where((i) => !i.isRetail).toList();
    final filtered = validCategoryIds == null
        ? rawIngredients
        : rawIngredients.where((i) {
            return i.categoryId != null && validCategoryIds.contains(i.categoryId);
          }).toList();

    final currency = context.watch<SettingsBloc>().state.currency;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.cookingPot,
              size: 48,
              color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'В этой категории пока нет сырья',
              style: AppTextStyles.h3.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isSelected = selectedIngredients.contains(item.id);
        String? iconStr;
        String catName = 'Без категории';
        if (catState is CategoryLoaded) {
          final cat = catState.categories.where((c) => c.id == item.categoryId).firstOrNull;
          iconStr = cat?.getInheritedIcon(catState.categories);
          if (cat != null) catName = cat.name;
        }

        return IngredientGridCard(
          item: item,
          isSelected: isSelected,
          isManageMode: isManageMode,
          catName: catName,
          iconStr: iconStr,
          currency: currency,
          onToggleSelect: onToggleSelect,
        );
      },
    );
  }
}
