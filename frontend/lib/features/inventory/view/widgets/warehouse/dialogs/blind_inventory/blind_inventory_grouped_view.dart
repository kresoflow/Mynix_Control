// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'blind_inventory_category_accordion.dart';
import 'blind_inventory_category_item_row.dart';

// ==============================================================================
// 2. КАТЕГОРИЙНЫЙ СПИСОК НОМЕНКЛАТУРЫ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Группировка номенклатуры ревизии с плоской виртуализацией (0 мс).
class BlindInventoryGroupedView extends StatelessWidget {
  final List<Ingredient> items;
  final Map<int, TextEditingController> controllers;
  final String searchQuery;
  final bool onlyUnfilled;
  final bool isAllExpanded;
  final Map<String, bool> expansionMap;
  final void Function(String category, bool isExpanded) onExpansionChanged;
  final VoidCallback onChanged;

  const BlindInventoryGroupedView({
    super.key,
    required this.items,
    required this.controllers,
    required this.searchQuery,
    required this.onlyUnfilled,
    required this.isAllExpanded,
    required this.expansionMap,
    required this.onExpansionChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Группировка элементов по категориям
    final Map<String, List<Ingredient>> grouped = {};
    for (final it in items) {
      if (it.isArchived) continue;

      if (searchQuery.isNotEmpty &&
          !it.name.toLowerCase().contains(searchQuery)) {
        continue;
      }

      if (onlyUnfilled && controllers[it.id]?.text.trim().isNotEmpty == true) {
        continue;
      }

      final cat = it.categoryName?.isNotEmpty == true
          ? it.categoryName!
          : 'Без категории';
      grouped.putIfAbsent(cat, () => []).add(it);
    }

    final categories = grouped.keys.toList()..sort();

    if (categories.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Center(
          child: Text(
            onlyUnfilled
                ? 'Все позиции в этой выборке уже пересчитаны!'
                : 'Позиции не найдены',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ),
      );
    }

    // 2. Построение плоского виртуализированного списка (Flat List Virtualization)
    final List<dynamic> flatList = [];
    for (final cat in categories) {
      final catItems = grouped[cat]!;
      final isExpanded = isAllExpanded ||
          searchQuery.isNotEmpty ||
          onlyUnfilled ||
          (expansionMap[cat] ?? false);

      flatList.add({
        'type': 'header',
        'categoryName': cat,
        'items': catItems,
        'isExpanded': isExpanded,
      });

      if (isExpanded) {
        for (int i = 0; i < catItems.length; i++) {
          final it = catItems[i];
          if (!controllers.containsKey(it.id)) {
            controllers[it.id] = TextEditingController();
          }
          flatList.add({
            'type': 'item',
            'item': it,
            'index': i,
            'isLast': i == catItems.length - 1,
          });
        }
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.44,
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: flatList.length,
        itemBuilder: (context, index) {
          final entry = flatList[index];
          if (entry['type'] == 'header') {
            final catName = entry['categoryName'] as String;
            return BlindInventoryCategoryAccordion(
              key: ValueKey('header-$catName'),
              categoryName: catName,
              items: entry['items'] as List<Ingredient>,
              controllers: controllers,
              isExpanded: entry['isExpanded'] as bool,
              onExpansionChanged: (exp) => onExpansionChanged(catName, exp),
            );
          } else {
            final item = entry['item'] as Ingredient;
            final isLast = entry['isLast'] as bool;
            final idx = entry['index'] as int;
            return BlindInventoryCategoryItemRow(
              key: ValueKey('item-${item.id}'),
              item: item,
              index: idx,
              controller: controllers[item.id]!,
              onChanged: onChanged,
              isLast: isLast,
            );
          }
        },
      ),
    );
  }
}
