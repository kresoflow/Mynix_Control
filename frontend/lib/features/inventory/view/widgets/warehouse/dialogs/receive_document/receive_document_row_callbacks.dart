import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_data.dart';
import 'receive_document_unit_helper.dart';

class ReceiveDocumentRowCallbacks {
  static void onRowIngredientSelected({
    required List<ReceiptRowData> items,
    required int index,
    required Ingredient selection,
    required VoidCallback onStateUpdate,
  }) {
    final item = items[index];
    item.ingredient = selection;
    item.nameController.text = selection.name;
    item.price = selection.costPerUnit;
    item.priceController.text = selection.costPerUnit.toStringAsFixed(2);
    item.selectedUnit = ReceiveDocumentUnitHelper.normalizeUnit(selection.unit);
    item.minStockAlert = selection.minStockAlert;
    item.minStockAlertController.text = selection.minStockAlert.toInt().toString();

    if (selection.attributes != null) {
      final flavor = selection.attributes!['Вкус'] ?? '';
      final vol = selection.attributes!['Объем'] ?? '';
      item.flavorController.text = flavor;
      item.volumeController.text = vol.replaceAll(RegExp(r'[^0-9.]'), '');
    }
    item.updateTotal();
    onStateUpdate();
    focusRow(item.qtyFocusNode);
  }

  static void focusRow(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  static void onRowNameChanged(ReceiptRowData item, String val, VoidCallback onClearIngredient) {
    item.newName = val;
    if (item.ingredient != null && item.ingredient!.name != val) {
      onClearIngredient();
    }
  }

  static void onRowNameSubmitted(ReceiptRowData item, int tabIndex) {
    if (tabIndex == 1) {
      focusRow(item.flavorFocusNode);
    } else {
      focusRow(item.qtyFocusNode);
    }
  }

  static void onRowPriceSubmitted({
    required List<ReceiptRowData> items,
    required int index,
    required int tabIndex,
    required VoidCallback onAddItem,
  }) {
    if (tabIndex == 1) {
      focusRow(items[index].sellPriceFocusNode);
    } else {
      if (index == items.length - 1) {
        onAddItem();
      } else {
        focusRow(items[index + 1].nameFocusNode);
      }
    }
  }

  static void onRowSellPriceSubmitted({
    required List<ReceiptRowData> items,
    required int index,
    required VoidCallback onAddItem,
  }) {
    if (index == items.length - 1) {
      onAddItem();
    } else {
      focusRow(items[index + 1].nameFocusNode);
    }
  }

  static KeyEventResult handleArrowKeyNavigation({
    required KeyEvent event,
    required List<ReceiptRowData> items,
    required int index,
    required FocusNode Function(ReceiptRowData item) targetNode,
    VoidCallback? onAddRowAtBottom,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (index < items.length - 1) {
        focusRow(targetNode(items[index + 1]));
        return KeyEventResult.handled;
      } else if (onAddRowAtBottom != null) {
        onAddRowAtBottom();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (index > 0) {
        focusRow(targetNode(items[index - 1]));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
