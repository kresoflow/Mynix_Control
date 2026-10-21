// ==============================================================================
// МОДУЛЬ: Справочник / Представление таблицы сырья (Ingredient Table View)
// ДОМЕН: lib/features/menu/view/widgets/catalog/ingredient/ingredient_table_view.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_deletion_dialogs.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_item_row.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

/// [UI-KIT] Табличный список позиций сырья с единым стилем контейнера и радиусов
class IngredientTableView extends StatelessWidget {
  final List<Ingredient> ingredients;
  final int? selectedCategoryId;
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final Function(int id, bool selected) onToggleSelect;

  const IngredientTableView({
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

    final rawIngredients = ingredients.where((i) => !i.isRetail).toList();
    final filteredIngredients = selectedCategoryId == null
        ? rawIngredients
        : rawIngredients.where((i) {
            if (i.categoryId == null) return false;
            final validIds = _getCategoryAndSubcategories(selectedCategoryId!, allCategories);
            return validIds.contains(i.categoryId);
          }).toList();

    final currency = context.watch<SettingsBloc>().state.currency;

    if (filteredIngredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppEmptyState(
          icon: PhosphorIconsRegular.cookingPot,
          title: 'В этой категории пока нет сырья',
          description: 'Используйте «Добавить» или «Массово» на верхней панели',
          size: AppEmptyStateSize.md,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filteredIngredients.length,
        itemBuilder: (context, index) {
          final item = filteredIngredients[index];

          String? iconStr;
          if (catState is CategoryLoaded) {
            final cat = catState.categories.where((c) => c.id == item.categoryId).firstOrNull;
            iconStr = cat?.getInheritedIcon(catState.categories);
          }

          return IngredientItemRow(
            item: item,
            categoryIcon: iconStr,
            currency: currency,
            isManageMode: isManageMode,
            isSelected: selectedIngredients.contains(item.id),
            onSelect: (val) => onToggleSelect(item.id, val == true),
            onEdit: () => showAddIngredientDialog(context, itemToEdit: item),
            onDelete: () => CatalogDeletionDialogs.confirmDeleteIngredient(context, item),
          );
        },
      ),
    );
  }
}
