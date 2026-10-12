// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'write_off_category_accordion.dart';
import 'write_off_category_item_row.dart';
import 'write_off_items_table.dart';

// ==============================================================================
// 2. СЕКЦИЯ КАТЕГОРИЙ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Каталог категорий списания с плоской виртуализацией (0 мс время отклика).
class WriteOffCategorySection extends StatefulWidget {
  final List<Ingredient> availableIngredients;
  final List<WriteOffItemEntry> activeEntries;
  final String currency;
  final void Function(Ingredient item, double qty) onQuantityChanged;

  const WriteOffCategorySection({
    super.key,
    required this.availableIngredients,
    required this.activeEntries,
    required this.currency,
    required this.onQuantityChanged,
  });

  @override
  State<WriteOffCategorySection> createState() =>
      _WriteOffCategorySectionState();
}

class _WriteOffCategorySectionState extends State<WriteOffCategorySection> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expansionMap = {};
  String _searchQuery = '';
  bool _isAllExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpandAll(List<String> categories) {
    setState(() {
      _isAllExpanded = !_isAllExpanded;
      for (final cat in categories) {
        _expansionMap[cat] = _isAllExpanded;
      }
    });
  }

  WriteOffItemEntry? _findEntry(int itemId) {
    for (final e in widget.activeEntries) {
      if (e.item.id == itemId) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Группировка ингредиентов по категориям
    final Map<String, List<Ingredient>> grouped = {};
    for (final it in widget.availableIngredients) {
      if (it.isArchived) continue;
      if (_searchQuery.isNotEmpty &&
          !it.name.toLowerCase().contains(_searchQuery)) {
        continue;
      }
      final cat = it.categoryName?.isNotEmpty == true
          ? it.categoryName!
          : 'Без категории';
      grouped.putIfAbsent(cat, () => []).add(it);
    }

    final categories = grouped.keys.toList()..sort();

    // 2. Построение плоского виртуализированного списка (Flat List Virtualization)
    final List<dynamic> flatList = [];
    for (final cat in categories) {
      final items = grouped[cat]!;
      final isExpanded = _isAllExpanded ||
          _searchQuery.isNotEmpty ||
          (_expansionMap[cat] ?? false);

      flatList.add({
        'type': 'header',
        'categoryName': cat,
        'items': items,
        'isExpanded': isExpanded,
      });

      if (isExpanded) {
        if (items.isNotEmpty) {
          flatList.add({
            'type': 'table_header',
            'categoryName': cat,
          });
        }
        for (int i = 0; i < items.length; i++) {
          flatList.add({
            'type': 'item',
            'item': items[i],
            'isLast': i == items.length - 1,
          });
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── Поиск и кнопка Развернуть все ───
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: _searchController,
                size: AppSearchFieldSize.sm,
                hintText: 'Фильтр позиций внутри категорий...',
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: categories.isEmpty
                  ? null
                  : () => _toggleExpandAll(categories),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAllExpanded
                          ? PhosphorIconsRegular.arrowsInSimple
                          : PhosphorIconsRegular.arrowsOutSimple,
                      size: 14,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isAllExpanded ? 'Свернуть' : 'Развернуть',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ─── Содержимое: Пустое состояние или виртуализированный список ───
        if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Center(
              child: Text(
                'Позиции не найдены',
                style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: flatList.length,
              itemBuilder: (context, index) {
                final entry = flatList[index];
                if (entry['type'] == 'header') {
                  final catName = entry['categoryName'] as String;
                  return WriteOffCategoryAccordion(
                    key: ValueKey('header-$catName'),
                    categoryName: catName,
                    items: entry['items'] as List<Ingredient>,
                    activeEntries: widget.activeEntries,
                    currency: widget.currency,
                    isExpanded: entry['isExpanded'] as bool,
                    onExpansionChanged: (exp) {
                      setState(() => _expansionMap[catName] = exp);
                    },
                  );
                } else if (entry['type'] == 'table_header') {
                  final catName = entry['categoryName'] as String;
                  return WriteOffCategoryTableHeader(
                    key: ValueKey('th-$catName'),
                    currency: widget.currency,
                  );
                } else {
                  final item = entry['item'] as Ingredient;
                  final isLast = entry['isLast'] as bool;
                  return WriteOffCategoryItemRow(
                    key: ValueKey('item-${item.id}'),
                    item: item,
                    entry: _findEntry(item.id),
                    currency: widget.currency,
                    onQuantityChanged: widget.onQuantityChanged,
                    isLast: isLast,
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
