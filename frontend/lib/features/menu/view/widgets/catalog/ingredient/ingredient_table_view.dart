import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/ingredient/ingredient_quick_setup_card.dart';
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.cookingPot,
                size: 56,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              const SizedBox(height: 16),
              Text(
                'В этой категории пока нет сырья',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Добавьте ингредиенты для техкарт и склада или примените готовые шаблоны полок:',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showAddIngredientDialog(context, initialCategoryId: selectedCategoryId);
                    },
                    icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                    label: const Text('Добавить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const BulkAddModal(initialTabIndex: 2),
                      );
                    },
                    icon: const Icon(PhosphorIconsRegular.listPlus, size: 16),
                    label: const Text('Массово'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => IngredientQuickSetupCard.showAsDialog(context),
                    icon: const Icon(PhosphorIconsRegular.cards, size: 16),
                    label: const Text('Шаблоны полок'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
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
                onDelete: () => context.read<IngredientBloc>().add(DeleteIngredient(item.id)),
              );
            },
          ),
        ),
      ),
    );
  }
}
