// ==============================================================================
// Title: StockSidePanel (stock_side_panel.dart)
// Path: frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_side_panel.dart
// Description: Боковая панель остатков склада: диаграмма капитала и низкий остаток.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'stock_capital_chart_card.dart';
import 'stock_low_inventory_widget.dart';

// ─── 1. Боковая информационная панель остатков склада ─────────────────────────

/// [UI-KIT] Правая аналитическая колонка для десктопного представления склада
class StockSidePanel extends StatelessWidget {
  final Map<String, double> categoryCapitals;
  final double totalCapital;
  final List<Ingredient> lowStockItems;
  final VoidCallback onReceiveTap;

  const StockSidePanel({
    super.key,
    required this.categoryCapitals,
    required this.totalCapital,
    required this.lowStockItems,
    required this.onReceiveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.only(
        right: 24,
        top: 8,
        bottom: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            StockCapitalChartCard(
              categoryCapitals: categoryCapitals,
              totalCapital: totalCapital,
              key: ValueKey(totalCapital),
            ),
            const SizedBox(height: 14),
            StockLowInventoryWidget(
              lowStockItems: lowStockItems,
              onReceiveTap: onReceiveTap,
            ),
          ],
        ),
      ),
    );
  }
}
