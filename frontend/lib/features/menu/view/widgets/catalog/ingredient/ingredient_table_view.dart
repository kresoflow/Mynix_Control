import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/ingredient/ingredient_item_row.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';

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
      final isDark = Theme.of(context).brightness == Brightness.dark;
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Используйте «Добавить» или «Массово» на верхней панели',
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
              onDelete: () => _confirmDeleteIngredient(context, item),
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteIngredient(BuildContext context, Ingredient item) {
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Удалить ингредиент?',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Сырьё «${item.name}» будет удалено со склада.\nЕсли позиция используется в техкартах блюд, удаление будет заблокировано.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSubtext
                : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.pop(ctx),
          ),
          AppDangerButton(
            label: 'Удалить',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              context.read<IngredientBloc>().add(DeleteIngredient(item.id));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
