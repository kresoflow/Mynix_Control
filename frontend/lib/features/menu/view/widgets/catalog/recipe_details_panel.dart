import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'dialogs/recipe_bulk_edit_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

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
            double costPerUnit = (r['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
            double qty = (r['quantity_required'] as num?)?.toDouble() ?? 0.0;
            totalCost += (costPerUnit * qty);
          }
          
          double margin = price - totalCost;
          double marginPercent = price > 0 ? (margin / price) * 100 : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analytics Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Себестоимость', '${totalCost.toStringAsFixed(2)} $currency', Colors.redAccent),
                    Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                    _buildStatColumn('Отпускная цена', '${price.toStringAsFixed(2)} $currency', Theme.of(context).colorScheme.primary),
                    Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                    _buildStatColumn('Маржа / Наценка', '${margin.toStringAsFixed(2)} $currency (${marginPercent.toStringAsFixed(1)}%)', margin >= 0 ? Colors.green : Colors.red),
                  ],
                ),
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
                          final recipe = state.recipes[index];
                          final ingredientId = recipe['ingredient_id'];
                          final qty = (recipe['quantity_required'] as num?)?.toDouble() ?? 0.0;
                          final unit = recipe['unit'] ?? 'ед.';
                          final costPerUnit = (recipe['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
                          final rowCost = qty * costPerUnit;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(PhosphorIconsRegular.cookingPot, color: Colors.grey),
                              ),
                              title: Text(recipe['ingredient_name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Стоимость: ${costPerUnit.toStringAsFixed(2)} $currency / $unit'),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Cost
                                  Container(
                                    width: 80,
                                    alignment: Alignment.centerRight,
                                    child: Text('${rowCost.toStringAsFixed(2)} $currency', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                  ),
                                  const SizedBox(width: 16),
                                  // Quantity Editor
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
                                          onPressed: qty <= 1 ? null : () {
                                            context.read<RecipeBloc>().add(
                                              UpdateIngredientQuantityInRecipe(
                                                menuItemId: selectedMenuItemId,
                                                ingredientId: ingredientId,
                                                quantity: qty - 1,
                                              ),
                                            );
                                          },
                                        ),
                                        Text('$qty $unit', style: const AppTextStyles.bodyLargeBold),
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
                                    icon: const Icon(PhosphorIconsRegular.trash, color: Colors.grey),
                                    hoverColor: Colors.red.withValues(alpha: 0.1),
                                    onPressed: () {
                                      context.read<RecipeBloc>().add(
                                        RemoveIngredientFromRecipe(
                                          menuItemId: selectedMenuItemId,
                                          ingredientId: ingredientId,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else if (state is RecipeError) {
          return Center(child: Text('Ошибка: ${state.message}', style: const TextStyle(color: Colors.red)));
        }
        return const Center(child: Text('Загрузка техкарты...'));
      },
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
