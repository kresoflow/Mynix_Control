import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'dialogs/recipe_bulk_edit_dialog.dart';
import 'recipe/recipe_analytics_header.dart';
import 'recipe/recipe_ingredient_item_tile.dart';

class RecipeDetailsPanel extends StatelessWidget {
  final int selectedMenuItemId;

  const RecipeDetailsPanel({super.key, required this.selectedMenuItemId});

  @override
  Widget build(BuildContext context) {
    final menuState = context.watch<MenuBloc>().state;
    final menuItem = menuState is MenuLoaded 
        ? menuState.items.where((i) => i.id == selectedMenuItemId).firstOrNull 
        : null;
    final price = menuItem?.price ?? 0.0;
    final currency = context.watch<SettingsBloc>().state.currency;

    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        if (state is RecipeLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecipeLoaded && state.menuItemId == selectedMenuItemId) {
          double totalCost = 0.0;
          for (var r in state.recipes) {
            final double costPerUnit = (r['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
            final double qty = (r['quantity_required'] as num?)?.toDouble() ?? 0.0;
            totalCost += (costPerUnit * qty);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeAnalyticsHeader(
                totalCost: totalCost,
                price: price,
                currency: currency,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ингредиенты (${state.recipes.length})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  BlocBuilder<IngredientBloc, IngredientState>(
                    builder: (context, ingState) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          if (ingState is IngredientLoaded) {
                            showDialog(
                              context: context,
                              builder: (_) => RecipeBulkEditDialog(
                                menuItemId: selectedMenuItemId,
                                availableIngredients: ingState.ingredients.where((i) => !i.isRetail).toList(),
                                currentRecipes: state.recipes,
                              ),
                            );
                          }
                        },
                        icon: const Icon(PhosphorIconsRegular.pencilSimple),
                        label: const Text('Редактировать состав'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.recipes.isEmpty)
                const Expanded(child: Center(child: Text('В техкарте пока нет ингредиентов.'))),
              if (state.recipes.isNotEmpty)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: state.recipes.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return RecipeIngredientItemTile(
                            recipe: state.recipes[index],
                            selectedMenuItemId: selectedMenuItemId,
                            currency: currency,
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else if (state is RecipeError) {
          return Center(child: Text('Ошибка: ${state.message}', style: const TextStyle(color: AppColors.danger)));
        }
        return const Center(child: Text('Загрузка техкарты...'));
      },
    );
  }
}
