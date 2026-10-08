// ==============================================================================
// МОДУЛЬ: Склад / Заголовок корневой категории остатков (L1)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock/stock_category_header.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_stock_category_accordion.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ─── 1. Виджет заголовка корневой категории (L1) ──────────────────────────────

/// [UI-KIT] Адаптер заголовка L1 для виртуализированного списка остатков склада.
class StockCategoryHeader extends StatelessWidget {
  final String categoryName;
  final List<Ingredient> items;
  final bool isExpanded;
  final VoidCallback onTap;

  const StockCategoryHeader({
    super.key,
    required this.categoryName,
    required this.items,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalCapital = 0;
    int lowStockCount = 0;
    for (final item in items) {
      if (item.currentStock > 0) {
        totalCapital += item.currentStock * item.costPerUnit;
      }
      if (item.isLowStock || item.currentStock <= 0) {
        lowStockCount++;
      }
    }

    final iconString = context.select<CategoryBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is CategoryLoaded) {
        final rootCat =
            state.categories.where((c) => c.name == categoryName).firstOrNull;
        return rootCat?.getInheritedIcon(state.categories);
      }
      return null;
    });

    final leadingWidget = (iconString != null && iconString.isNotEmpty)
        ? IconHelper.buildIcon(
            iconString,
            size: 20,
            color: isExpanded
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          )
        : null;

    return AppStockCategoryAccordion(
      title: categoryName,
      isSubcategory: false,
      leading: leadingWidget,
      itemCount: items.length,
      lowStockCount: lowStockCount,
      totalSum: totalCapital > 0 ? totalCapital : null,
      isExpanded: isExpanded,
      onExpansionChanged: (_) => onTap(),
      child: null,
    );
  }
}
