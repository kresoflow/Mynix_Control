// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'write_off_category_accordion.dart';
import 'write_off_items_table.dart';

// ==============================================================================
// 2. СЕКЦИЯ КАТЕГОРИЙ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Каталог категорий склада с локальным поиском и аккордеонами.
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
  final Map<String, bool> _expansionMap = {};
  String _searchQuery = '';
  bool _isAllExpanded = false;

  void _toggleExpandAll(List<String> categories) {
    setState(() {
      _isAllExpanded = !_isAllExpanded;
      for (final cat in categories) {
        _expansionMap[cat] = _isAllExpanded;
      }
    });
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Фильтр позиций внутри категорий...',
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.magnifyingGlass,
                      size: 16,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ),
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
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                  color:
                      isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isExpanded = _isAllExpanded ||
                    _searchQuery.isNotEmpty ||
                    (_expansionMap[cat] ?? false);

                return WriteOffCategoryAccordion(
                  categoryName: cat,
                  items: grouped[cat]!,
                  activeEntries: widget.activeEntries,
                  currency: widget.currency,
                  isExpanded: isExpanded,
                  onExpansionChanged: (exp) {
                    setState(() => _expansionMap[cat] = exp);
                  },
                  onQuantityChanged: widget.onQuantityChanged,
                );
              },
            ),
          ),
      ],
    );
  }
}
