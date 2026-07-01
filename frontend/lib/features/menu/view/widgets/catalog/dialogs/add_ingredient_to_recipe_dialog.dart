import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/recipe_event.dart';

void showAddIngredientToRecipeDialog(BuildContext context, int menuItemId, List<dynamic> ingredients) {
  int? selectedIngredientId;
  final qtyController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Добавить ингредиент в техкарту'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedIngredientId,
                  decoration: const InputDecoration(labelText: 'Сырье'),
                  items: ingredients.map((ing) {
                    return DropdownMenuItem<int>(
                      value: ing.id,
                      child: Text('${ing.name} (${ing.unit})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedIngredientId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Количество по норме'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(qtyController.text) ?? 0;
                  if (selectedIngredientId != null && qty > 0) {
                    context.read<RecipeBloc>().add(
                          AddIngredientToRecipe(
                            menuItemId: menuItemId,
                            ingredientId: selectedIngredientId!,
                            quantity: qty,
                          ),
                        );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      );
    },
  );
}
