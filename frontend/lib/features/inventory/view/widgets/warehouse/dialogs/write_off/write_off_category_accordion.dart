// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_stock_category_accordion.dart';
import 'write_off_items_table.dart';
import 'write_off_category_item_row.dart';

// ==============================================================================
// 2. АККОРДЕОН КАТЕГОРИИ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Аккордеон категории склада для быстрого списания позиций группы.
class WriteOffCategoryAccordion extends StatelessWidget {
  final String categoryName;
  final List<Ingredient> items;
  final List<WriteOffItemEntry> activeEntries;
  final String currency;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final void Function(Ingredient item, double qty) onQuantityChanged;

  const WriteOffCategoryAccordion({
    super.key,
    required this.categoryName,
    required this.items,
    required this.activeEntries,
    required this.currency,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onQuantityChanged,
  });

  WriteOffItemEntry? _findEntry(int itemId) {
    for (final e in activeEntries) {
      if (e.item.id == itemId) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int writtenOffCount = 0;
    double writtenOffSum = 0.0;

    for (final item in items) {
      final entry = _findEntry(item.id);
      if (entry != null && entry.quantity > 0) {
        writtenOffCount++;
        writtenOffSum += entry.total;
      }
    }

    final iconString = context.select<CategoryBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is CategoryLoaded) {
        return state.categories
            .where((c) => c.name == categoryName)
            .firstOrNull
            ?.getInheritedIcon(state.categories);
      }
      return null;
    });

    return AppStockCategoryAccordion(
      title: categoryName,
      leading: (iconString != null && iconString.isNotEmpty)
          ? IconHelper.buildIcon(
              iconString,
              size: 18,
              color: isExpanded
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            )
          : null,
      isExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      itemCount: items.length,
      totalSum: writtenOffSum > 0 ? writtenOffSum : null,
      currency: currency,
      isHighlighted: writtenOffCount > 0,
      trailingBadge: writtenOffCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Списано: $writtenOffCount поз.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            )
          : null,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return WriteOffCategoryItemRow(
            item: item,
            entry: _findEntry(item.id),
            currency: currency,
            onQuantityChanged: onQuantityChanged,
          );
        },
      ),
    );
  }
}
