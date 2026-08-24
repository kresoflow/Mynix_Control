import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_data.dart';
import 'receive_document_item_row.dart';

class ReceiveDocumentItemsList extends StatelessWidget {
  final bool isLoading;
  final List<ReceiptRowData> items;
  final List<Ingredient> availableIngredients;
  final int tabIndex;
  final Function(int index, Ingredient selection) onIngredientSelected;
  final Function(int index, String name) onNameChanged;
  final Function(int index) onNameSubmitted;
  final Function(int index) onFlavorSubmitted;
  final Function(int index) onVolumeSubmitted;
  final Function(int index) onQtySubmitted;
  final Function(int index) onMinStockAlertSubmitted;
  final Function(int index) onPriceSubmitted;
  final Function(int index) onSellPriceSubmitted;
  final Function(int index, String? unit) onUnitChanged;
  final Function(int index, String qty) onQtyChanged;
  final Function(int index, String alert) onMinStockAlertChanged;
  final Function(int index, String price) onPriceChanged;
  final Function(int index, String sellPrice) onSellPriceChanged;
  final Function(int index) onRemove;

  const ReceiveDocumentItemsList({
    super.key,
    required this.isLoading,
    required this.items,
    required this.availableIngredients,
    required this.tabIndex,
    required this.onIngredientSelected,
    required this.onNameChanged,
    required this.onNameSubmitted,
    required this.onFlavorSubmitted,
    required this.onVolumeSubmitted,
    required this.onQtySubmitted,
    required this.onMinStockAlertSubmitted,
    required this.onPriceSubmitted,
    required this.onSellPriceSubmitted,
    required this.onUnitChanged,
    required this.onQtyChanged,
    required this.onMinStockAlertChanged,
    required this.onPriceChanged,
    required this.onSellPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        return ReceiveDocumentItemRow(
          item: item,
          index: index,
          isLast: index == items.length - 1,
          availableIngredients: availableIngredients,
          tabIndex: tabIndex,
          onIngredientSelected: (sel) => onIngredientSelected(index, sel),
          onNameChanged: (val) => onNameChanged(index, val),
          onNameSubmitted: () => onNameSubmitted(index),
          onFlavorSubmitted: () => onFlavorSubmitted(index),
          onVolumeSubmitted: () => onVolumeSubmitted(index),
          onQtySubmitted: () => onQtySubmitted(index),
          onMinStockAlertSubmitted: () => onMinStockAlertSubmitted(index),
          onPriceSubmitted: () => onPriceSubmitted(index),
          onSellPriceSubmitted: () => onSellPriceSubmitted(index),
          onUnitChanged: (val) => onUnitChanged(index, val),
          onQtyChanged: (val) => onQtyChanged(index, val),
          onMinStockAlertChanged: (val) => onMinStockAlertChanged(index, val),
          onPriceChanged: (val) => onPriceChanged(index, val),
          onSellPriceChanged: (val) => onSellPriceChanged(index, val),
          onRemove: () => onRemove(index),
        );
      },
    );
  }
}
