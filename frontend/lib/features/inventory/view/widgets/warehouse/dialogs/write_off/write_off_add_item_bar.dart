import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class WriteOffAddItemBar extends StatelessWidget {
  final List<Ingredient> availableIngredients;
  final ValueChanged<Ingredient> onIngredientSelected;

  const WriteOffAddItemBar({
    super.key,
    required this.availableIngredients,
    required this.onIngredientSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Autocomplete<Ingredient>(
      displayStringForOption: (item) => '${item.name} (${item.currentStock} ${item.unit})',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Ingredient>.empty();
        }
        final q = textEditingValue.text.toLowerCase().trim();
        return availableIngredients.where((item) => item.name.toLowerCase().contains(q));
      },
      onSelected: onIngredientSelected,
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Начните вводить название сырья или товара...',
            prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
            isDense: true,
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
        );
      },
    );
  }
}
