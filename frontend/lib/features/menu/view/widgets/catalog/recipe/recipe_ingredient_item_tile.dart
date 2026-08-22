import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';

class RecipeIngredientItemTile extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final int selectedMenuItemId;
  final String currency;

  const RecipeIngredientItemTile({
    super.key,
    required this.recipe,
    required this.selectedMenuItemId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final ingredientId = recipe['ingredient_id'];
    final qty = (recipe['quantity_required'] as num?)?.toDouble() ?? 0.0;
    final unit = recipe['unit'] ?? 'ед.';
    final costPerUnit = (recipe['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
    final rowCost = qty * costPerUnit;

    final ingState = context.watch<IngredientBloc>().state;
    final ing = ingState is IngredientLoaded 
        ? ingState.ingredients.where((i) => i.id == ingredientId).firstOrNull 
        : null;
    final catState = context.watch<CategoryBloc>().state;
    final cat = (ing != null && catState is CategoryLoaded) 
        ? catState.categories.where((c) => c.id == ing.categoryId).firstOrNull 
        : null;
    final iconStr = (cat != null && catState is CategoryLoaded) 
        ? cat.getInheritedIcon(catState.categories) 
        : null;

    final bool hasIcon = iconStr != null &&
        iconStr.isNotEmpty &&
        (IconHelper.getIcon(iconStr) != null || iconStr.startsWith('svg:'));

    final String ingName = recipe['ingredient_name'] ?? 'Unknown';

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: hasIcon
            ? Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: IconHelper.buildIcon(
                  iconStr,
                  size: 18,
                  color: AppColors.brandPrimary,
                ),
              )
            : null,
        title: Text(
          ingName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Стоимость: ${costPerUnit.toStringAsFixed(2)} $currency / $unit'),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              alignment: Alignment.centerRight,
              child: Text(
                '${rowCost.toStringAsFixed(2)} $currency',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.minus, size: 16),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: qty <= 1
                        ? null
                        : () {
                            context.read<RecipeBloc>().add(
                              UpdateIngredientQuantityInRecipe(
                                menuItemId: selectedMenuItemId,
                                ingredientId: ingredientId,
                                quantity: qty - 1,
                              ),
                            );
                          },
                  ),
                  Text('$qty $unit', style: AppTextStyles.h3),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () {
                      context.read<RecipeBloc>().add(
                        UpdateIngredientQuantityInRecipe(
                          menuItemId: selectedMenuItemId,
                          ingredientId: ingredientId,
                          quantity: qty + 1,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger),
              tooltip: 'Удалить из рецепта',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => MynixDialog(
                    title: 'Удаление ингредиента',
                    icon: PhosphorIconsRegular.trash,
                    isDestructive: true,
                    content: Text('Удалить $ingName из рецепта?'),
                    actions: [
                      AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
                      AppDangerButton(
                        label: 'Удалить',
                        onPressed: () {
                          context.read<RecipeBloc>().add(
                            RemoveIngredientFromRecipe(
                              menuItemId: selectedMenuItemId,
                              ingredientId: ingredientId,
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
