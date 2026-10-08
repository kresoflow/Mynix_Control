// ==============================================================================
// МОДУЛЬ: Склад / Заголовок подкатегории остатков (L2)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock/stock_subcategory_header.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_stock_category_accordion.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ─── 1. Виджет заголовка подкатегории (L2) ────────────────────────────────────

/// [UI-KIT] Адаптер заголовка L2 для виртуализированного списка остатков склада.
///
/// Наследует стандартизированные визуальные токены и отступы L2 от
/// [AppStockCategoryAccordion] с поддержкой отображения дефицита и капитала.
/// Используется в плоском списке `StockTab` для оптимизации скролла большого
/// количества складских позиций без вложенных ListView.
class StockSubcategoryHeader extends StatelessWidget {
  final String subcategoryName;
  final List<Ingredient> items;
  final bool isExpanded;
  final VoidCallback onTap;

  const StockSubcategoryHeader({
    super.key,
    required this.subcategoryName,
    required this.items,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Подсчет локальной статистики по позициям подкатегории
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

    return AppStockCategoryAccordion(
      title: subcategoryName,
      isSubcategory: true,
      icon: isExpanded
          ? PhosphorIconsRegular.folderOpen
          : PhosphorIconsRegular.folder,
      itemCount: items.length,
      lowStockCount: lowStockCount,
      totalSum: totalCapital > 0 ? totalCapital : null,
      isExpanded: isExpanded,
      onExpansionChanged: (_) => onTap(),
      child: null,
    );
  }
}
