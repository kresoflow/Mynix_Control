import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IngredientPickerDialog extends StatelessWidget {
  final List<dynamic> availableIngredients;

  const IngredientPickerDialog({
    super.key,
    required this.availableIngredients,
  });

  static Future<int?> show(BuildContext context, List<dynamic> availableIngredients) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => IngredientPickerDialog(availableIngredients: availableIngredients),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<dynamic>> grouped = {};
    for (var ing in availableIngredients) {
      final catName = ing.categoryName ?? 'Без категории';
      grouped.putIfAbsent(catName, () => []).add(ing);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return Dialog(
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
                Text('Выберите сырье', style: AppTextStyles.h3),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: StatefulBuilder(
                builder: (ctx, setDialogState) {
                  final Map<String, bool> expandedCats = {};

                  List<dynamic> buildFlatList() {
                    final list = <dynamic>[];
                    for (final catName in sortedKeys) {
                      final items = grouped[catName]!;
                      final isExpanded = expandedCats[catName] ?? false;

                      list.add({
                        'type': 'header',
                        'categoryName': catName,
                        'isExpanded': isExpanded,
                      });

                      if (isExpanded) {
                        list.addAll(items.map((item) => {'type': 'item', 'item': item}));
                      }
                    }
                    return list;
                  }

                  var flatList = buildFlatList();

                  return ListView.builder(
                    itemCount: flatList.length,
                    itemBuilder: (context, index) {
                      final data = flatList[index];
                      if (data['type'] == 'header') {
                        final catName = data['categoryName'] as String;
                        final isExpanded = data['isExpanded'] as bool;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                expandedCats[catName] = !isExpanded;
                                flatList = buildFlatList();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text(catName, style: AppTextStyles.h3)),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const Icon(
                                      PhosphorIconsRegular.caretDown,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        final ing = data['item'];
                        return ListTile(
                          title: Text(ing.name),
                          subtitle: Text(
                            'Алерт: ${ing.minStockAlert.toInt()} ${ing.unit} | Остаток: ${ing.currentStock.toInt()} ${ing.unit}',
                          ),
                          trailing: Text(ing.unit, style: const TextStyle(color: Colors.grey)),
                          onTap: () => Navigator.of(context).pop(ing.id),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
