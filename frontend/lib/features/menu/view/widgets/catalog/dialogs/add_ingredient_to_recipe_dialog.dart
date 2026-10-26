// ==============================================================================
// Title: AddIngredientToRecipeDialog
// Path: frontend/lib/features/menu/view/widgets/catalog/dialogs/add_ingredient_to_recipe_dialog.dart
// Description: Диалог добавления ингредиента в технологическую карту блюда.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_event.dart';

// ─── 1. Показ диалога добавления сырья в техкарту ─────────────────────────────

void showAddIngredientToRecipeDialog(
  BuildContext context,
  int menuItemId,
  List<dynamic> ingredients,
) {
  int? selectedIngredientId;
  final qtyController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          void submit() {
            final qty = double.tryParse(qtyController.text.replaceAll(',', '.')) ?? 0;
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
          }

          return AppDialog(
            title: 'Ингредиент в техкарту',
            icon: PhosphorIconsRegular.leaf,
            width: 440,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedIngredientId,
                  decoration: const InputDecoration(labelText: 'Сырье'),
                  items: ingredients.map((ing) {
                    return DropdownMenuItem<int>(
                      value: ing.id,
                      child: Text('${ing.name} (${UnitFormatter.format(ing.unit)})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedIngredientId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  labelText: 'Количество по норме',
                  hintText: '0.00',
                ),
              ],
            ),
            actions: [
              AppGhostButton(
                onPressed: () => Navigator.pop(ctx),
                label: 'Отмена',
              ),
              const SizedBox(width: 12),
              AppPrimaryButton(
                onPressed: submit,
                label: 'Добавить',
                icon: PhosphorIconsRegular.plus,
              ),
            ],
          );
        },
      );
    },
  );
}
