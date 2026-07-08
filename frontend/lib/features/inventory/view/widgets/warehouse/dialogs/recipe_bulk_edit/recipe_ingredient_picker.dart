import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

Future<int?> showRecipeIngredientPicker(BuildContext context, List<dynamic> availableIngredients) {
  final Map<String, List<dynamic>> grouped = {};
  for (var ing in availableIngredients) {
    final catName = ing.categoryName ?? 'Без категории';
    grouped.putIfAbsent(catName, () => []).add(ing);
  }
  
  final sortedKeys = grouped.keys.toList()..sort();

  return showDialog<int>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Выберите сырье', style: AppTextStyles.h3),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x),
                  onPressed: () => Navigator.of(ctx).pop(),
                )
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final catName = sortedKeys[index];
                  final items = grouped[catName]!;
                  return ExpansionTile(
                    title: Text(catName, style: const AppTextStyles.bodyLargeBold),
                    initiallyExpanded: false,
                    shape: const Border(),
                    children: items.map((ing) => ListTile(
                      title: Text(ing.name),
                      subtitle: Text('Алерт: ${ing.minStockAlert.toInt()} ${ing.unit} | Остаток: ${ing.currentStock.toInt()} ${ing.unit}'),
                      trailing: Text(ing.unit, style: const TextStyle(color: Colors.grey)),
                      onTap: () {
                        Navigator.of(ctx).pop(ing.id);
                      },
                    )).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
