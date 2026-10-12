import 'package:flutter/material.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_data.dart';
import 'receive_document_items_list.dart';
import 'receive_document_row_callbacks.dart';
import 'receive_document_table_header.dart';

class ReceiveDocumentTableSection extends StatelessWidget {
  final bool isLoading;
  final List<ReceiptRowData> items;
  final List<Ingredient> availableIngredients;
  final int tabIndex;
  final String currency;
  final ValueNotifier<double> totalSumNotifier;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onTotalChanged;
  final ValueChanged<VoidCallback> onStateUpdate;

  const ReceiveDocumentTableSection({
    super.key,
    required this.isLoading,
    required this.items,
    required this.availableIngredients,
    required this.tabIndex,
    required this.currency,
    required this.totalSumNotifier,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onTotalChanged,
    required this.onStateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final minWidth = (tabIndex == 0 || tabIndex == 1) ? 1040.0 : 880.0;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;

          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: targetWidth,
                child: Column(
                  children: [
                    ReceiveDocumentTableHeader(currency: currency, tabIndex: tabIndex),
                    Expanded(
                      child: ReceiveDocumentItemsList(
              isLoading: isLoading,
              items: items,
              availableIngredients: availableIngredients,
              tabIndex: tabIndex,
              onIngredientSelected: (i, sel) => ReceiveDocumentRowCallbacks.onRowIngredientSelected(
                items: items,
                index: i,
                selection: sel,
                onStateUpdate: () {
                  onTotalChanged();
                  onStateUpdate(() {});
                },
              ),
              onNameChanged: (i, val) => ReceiveDocumentRowCallbacks.onRowNameChanged(
                items[i],
                val,
                () => onStateUpdate(() => items[i].ingredient = null),
              ),
              onNameSubmitted: (i) => ReceiveDocumentRowCallbacks.onRowNameSubmitted(items[i], tabIndex),
              onFlavorSubmitted: (i) => ReceiveDocumentRowCallbacks.focusRow(items[i].volumeFocusNode),
              onVolumeSubmitted: (i) => ReceiveDocumentRowCallbacks.focusRow(items[i].qtyFocusNode),
              onQtySubmitted: (i) => ReceiveDocumentRowCallbacks.focusRow(items[i].minStockAlertFocusNode),
              onMinStockAlertSubmitted: (i) => ReceiveDocumentRowCallbacks.focusRow(items[i].priceFocusNode),
              onPriceSubmitted: (i) => ReceiveDocumentRowCallbacks.onRowPriceSubmitted(
                items: items,
                index: i,
                tabIndex: tabIndex,
                onAddItem: onAddItem,
              ),
              onSellPriceSubmitted: (i) => ReceiveDocumentRowCallbacks.onRowSellPriceSubmitted(
                items: items,
                index: i,
                onAddItem: onAddItem,
              ),
              onUnitChanged: (i, val) {
                if (val != null) onStateUpdate(() => items[i].selectedUnit = val);
              },
              onQtyChanged: (i, val) {
                final n = double.tryParse(val.replaceAll(',', '.'));
                if (n != null) {
                  items[i].quantity = n;
                  items[i].updateTotal();
                  onTotalChanged();
                }
              },
              onMinStockAlertChanged: (i, val) {
                final n = double.tryParse(val.replaceAll(',', '.'));
                if (n != null) items[i].minStockAlert = n;
              },
              onPriceChanged: (i, val) {
                final n = double.tryParse(val.replaceAll(',', '.'));
                if (n != null) {
                  items[i].price = n;
                  items[i].updateTotal();
                  onTotalChanged();
                }
              },
              onSellPriceChanged: (i, val) {
                final n = double.tryParse(val.replaceAll(',', '.'));
                if (n != null) items[i].sellPrice = n;
              },
              onRemove: onRemoveItem,
            ),
          ),
        ],
      ),
    ),
  ),
);
        },
      ),
    );
  }
}
