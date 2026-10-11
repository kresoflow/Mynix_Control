// ==============================================================================
// МОДУЛЬ: Каталог / Секция таблицы спецификации ингредиентов техкарты
// ДОМЕН: lib/features/menu/view/widgets/catalog/recipe/recipe_specification_section.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/recipe_event.dart';

class RecipeSpecificationSection extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;
  final int targetMenuItemId;
  final String currency;
  final bool isDark;
  final VoidCallback onAddIngredient;

  const RecipeSpecificationSection({
    super.key,
    required this.recipes,
    required this.targetMenuItemId,
    required this.currency,
    required this.isDark,
    required this.onAddIngredient,
  });

  void _confirmDelete(BuildContext context, int ingId, String ingName) {
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Удаление из техкарты',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        content: Text('Удалить $ingName из техкарты?'),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppDangerButton(
            label: 'Удалить',
            onPressed: () {
              context.read<RecipeBloc>().add(
                    RemoveIngredientFromRecipe(
                      menuItemId: targetMenuItemId,
                      ingredientId: ingId,
                    ),
                  );
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: AppEmptyState(
          icon: PhosphorIconsRegular.cookingPot,
          title: 'В техкарте пока нет ингредиентов',
          description: 'Добавьте сырье и граммовки для автоматического списания со склада при продаже блюда.',
          size: AppEmptyStateSize.md,
          action: AppPrimaryButton(
            label: 'Добавить первый ингредиент',
            icon: PhosphorIconsRegular.plus,
            size: AppButtonSize.md,
            onPressed: onAddIngredient,
          ),
        ),
      );
    }

    final specItems = recipes.asMap().entries.map((entry) {
      final r = entry.value;
      final ingId = r['ingredient_id']?.toString() ?? '';
      final ingName = r['ingredient_name']?.toString() ?? 'Ингредиент';
      final qty = (r['quantity_required'] as num?)?.toDouble() ?? 0.0;
      final unit = UnitFormatter.format(r['unit']);
      final costPerUnit = (r['cost_per_unit'] as num?)?.toDouble() ?? 0.0;
      final rowCost = qty * costPerUnit;

      return AppSpecificationRowData(
        id: ingId,
        title: ingName,
        subtitle: 'Стоимость: ${costPerUnit.toStringAsFixed(2)} $currency / $unit',
        quantity: qty,
        unit: unit,
        price: costPerUnit,
        total: rowCost,
      );
    }).toList();

    return SingleChildScrollView(
      child: AppSpecificationTable(
        items: specItems,
        allowDecimals: true,
        onQuantityChanged: (index, newQuantity) {
          final r = recipes[index];
          final ingId = r['ingredient_id'] as int;
          context.read<RecipeBloc>().add(
                UpdateIngredientQuantityInRecipe(
                  menuItemId: targetMenuItemId,
                  ingredientId: ingId,
                  quantity: newQuantity,
                ),
              );
        },
        onDeleteRow: (index) {
          final r = recipes[index];
          final ingId = r['ingredient_id'] as int;
          final ingName = r['ingredient_name']?.toString() ?? 'ингредиент';
          _confirmDelete(context, ingId, ingName);
        },
      ),
    );
  }
}
