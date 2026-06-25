import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/recipe_event.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'dialogs/add_ingredient_to_recipe_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecipeDetailsPanel extends StatelessWidget {
  final int selectedMenuItemId;

  const RecipeDetailsPanel({super.key, required this.selectedMenuItemId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        if (state is RecipeLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecipeLoaded && state.menuItemId == selectedMenuItemId) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            showAddIngredientToRecipeDialog(
                                context, selectedMenuItemId, ingState.ingredients);
                          }
                        },
                        icon: const Icon(PhosphorIconsRegular.plus),
                        label: const Text('Добавить'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.recipes.isEmpty)
                const Center(child: Text('В техкарте пока нет ингредиентов.')),
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
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(recipe['ingredient_name'] ?? 'Unknown', style: const TextStyle(fontSize: 16)),
                            subtitle: Text('Расход: ${recipe['quantity_required']} ед.'),
                            trailing: IconButton(
                              icon: const Icon(PhosphorIconsRegular.trash, color: Colors.grey),
                              hoverColor: Colors.red.withValues(alpha: 0.1),
                              onPressed: () {
                                context.read<RecipeBloc>().add(
                                  RemoveIngredientFromRecipe(
                                    menuItemId: selectedMenuItemId,
                                    ingredientId: recipe['ingredient_id'],
                                  ),
                                );
                              },
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
        }
        return const Center(child: Text('Загрузка техкарты...'));
      },
    );
  }
}
