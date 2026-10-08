// ==============================================================================
// МОДУЛЬ: Склад / Аккордеон категории в приходной накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_stock_category_accordion.dart';
import 'receive_category_item_row.dart';
import 'receive_category_sync_adapter.dart';

/// Аккордеон папки категории склада с отображением товаров и инпутов прихода.
class ReceiveCategoryAccordion extends StatelessWidget {
  final String categoryName;
  final List<Ingredient> items;
  final bool isRetail;
  final String currency;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final ReceiveCategorySyncAdapter adapter;

  const ReceiveCategoryAccordion({
    super.key,
    required this.categoryName,
    required this.items,
    required this.isRetail,
    required this.currency,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.adapter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Подсчет статистики категории
    int lowStockCount = 0;
    int itemsInReceiptCount = 0;
    double categoryTotalSum = 0.0;

    for (var item in items) {
      if (item.isLowStock || item.currentStock <= item.minStockAlert) {
        lowStockCount++;
      }
      final qty = adapter.getQuantity(item);
      if (qty > 0) {
        itemsInReceiptCount++;
        final price = adapter.getCostPrice(item);
        categoryTotalSum += (qty * price);
      }
    }
    final bool showRetailColumn = isRetail || items.any((i) => i.isRetail);

    final iconString = context.select<CategoryBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is CategoryLoaded) {
        return state.categories.where((c) => c.name == categoryName).firstOrNull?.getInheritedIcon(state.categories);
      }
      return null;
    });

    return AppStockCategoryAccordion(
      title: categoryName,
      leading: (iconString != null && iconString.isNotEmpty)
          ? IconHelper.buildIcon(
              iconString,
              size: 20,
              color: isExpanded
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            )
          : null,
      isExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      lowStockCount: lowStockCount,
      itemCount: items.length,
      totalSum: categoryTotalSum > 0 ? categoryTotalSum : null,
      currency: currency,
      isHighlighted: itemsInReceiptCount > 0,
      trailingBadge: itemsInReceiptCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$itemsInReceiptCount к приходу',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategoryTableHeader(context, isDark, showRetailColumn),
          ...items.map(
            (item) => ReceiveCategoryItemRow(
              key: ValueKey(item.id),
              item: item,
              showRetailColumn: showRetailColumn,
              currency: currency,
              adapter: adapter,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCategoryTableHeader(BuildContext context, bool isDark, bool showRetail) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? AppColors.darkSurface : AppColors.lightBg,
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Товар', style: style)),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text('Остаток', style: style)),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text('Приход', textAlign: TextAlign.center, style: style)),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text('Закупка ($currency)', textAlign: TextAlign.right, style: style)),
          if (showRetail) ...[
            const SizedBox(width: 8),
            SizedBox(width: 90, child: Text('Продажа ($currency)', textAlign: TextAlign.right, style: style)),
          ],
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text('Сумма ($currency)', textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}
