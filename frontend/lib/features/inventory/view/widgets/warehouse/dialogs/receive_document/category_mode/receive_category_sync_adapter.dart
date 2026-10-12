// ==============================================================================
// МОДУЛЬ: Склад / Адаптер синхронизации прихода по категориям
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import '../receipt_row_data.dart';

/// Режим отображения и ввода позиций в приходной накладной.
enum ReceiveViewMode {
  /// Классический строчный ввод по накладной от поставщика с автокомплитом.
  lines,

  /// Иерархический режим Excel-аккордеонов склада с группировкой по категориям.
  categories,
}

/// Адаптер двусторонней синхронизации между каталогом категорий склада
/// и плоским списком позиций накладной [ReceiptRowData].
class ReceiveCategorySyncAdapter {
  final List<ReceiptRowData> items;
  final VoidCallback onTotalChanged;

  const ReceiveCategorySyncAdapter({
    required this.items,
    required this.onTotalChanged,
  });

  /// Находит строку накладной, привязанную к конкретному ингредиенту/товару.
  ReceiptRowData? getRowForIngredient(int ingredientId) {
    return items.where((r) => r.ingredient?.id == ingredientId).firstOrNull;
  }

  /// Возвращает текущее введённое количество к приходу для позиции каталога.
  double getQuantity(Ingredient ingredient) {
    final row = getRowForIngredient(ingredient.id);
    return row?.quantity ?? 0.0;
  }

  /// Возвращает закупочную цену (из строки накладной либо последнюю из каталога).
  double getCostPrice(Ingredient ingredient) {
    final row = getRowForIngredient(ingredient.id);
    if (row != null && row.price > 0) {
      return row.price;
    }
    return ingredient.costPerUnit;
  }

  /// Возвращает розничную цену продажи (для витрины).
  double getSellPrice(Ingredient ingredient) {
    final row = getRowForIngredient(ingredient.id);
    if (row != null && row.sellPrice > 0) {
      return row.sellPrice;
    }
    return ingredient.price ?? 0.0;
  }

  /// Проверяет, добавлена ли позиция в текущую накладную с ненулевым приходом.
  bool isInReceipt(int ingredientId) {
    final row = getRowForIngredient(ingredientId);
    return row != null && row.quantity > 0;
  }

  /// Обновляет количество прихода для позиции.
  /// При qty > 0 автоматически создаёт или обновляет [ReceiptRowData].
  void updateQuantity(Ingredient ingredient, double qty) {
    var row = getRowForIngredient(ingredient.id);

    if (qty > 0) {
      if (row == null) {
        row = ReceiptRowData(
          ingredient: ingredient,
          newName: ingredient.name,
          quantity: qty,
          price: ingredient.costPerUnit,
          sellPrice: ingredient.price ?? 0.0,
          minStockAlert: ingredient.minStockAlert,
          selectedUnit: ingredient.unit,
        );
        _fillRetailAttributes(row, ingredient);
        items.add(row);
      } else {
        row.quantity = qty;
        row.qtyController.text = _formatNum(qty);
        if (row.price == 0 && ingredient.costPerUnit > 0) {
          row.price = ingredient.costPerUnit;
          row.priceController.text = _formatNum(ingredient.costPerUnit);
        }
        row.updateTotal();
      }
    } else {
      if (row != null) {
        row.quantity = 0.0;
        row.qtyController.text = '0';
        row.updateTotal();
      }
    }
    onTotalChanged();
  }

  /// Обновляет цену закупки позиции в накладной.
  void updateCostPrice(Ingredient ingredient, double price) {
    var row = getRowForIngredient(ingredient.id);
    if (row == null) {
      row = ReceiptRowData(
        ingredient: ingredient,
        newName: ingredient.name,
        quantity: 0.0,
        price: price,
        sellPrice: ingredient.price ?? 0.0,
        minStockAlert: ingredient.minStockAlert,
        selectedUnit: ingredient.unit,
      );
      _fillRetailAttributes(row, ingredient);
      items.add(row);
    } else {
      row.price = price;
      row.priceController.text = _formatNum(price);
      row.updateTotal();
    }
    onTotalChanged();
  }

  /// Обновляет розничную цену продажи позиции.
  void updateSellPrice(Ingredient ingredient, double sellPrice) {
    var row = getRowForIngredient(ingredient.id);
    if (row == null) {
      row = ReceiptRowData(
        ingredient: ingredient,
        newName: ingredient.name,
        quantity: 0.0,
        price: ingredient.costPerUnit,
        sellPrice: sellPrice,
        minStockAlert: ingredient.minStockAlert,
        selectedUnit: ingredient.unit,
      );
      _fillRetailAttributes(row, ingredient);
      items.add(row);
    } else {
      row.sellPrice = sellPrice;
      row.sellPriceController.text = _formatNum(sellPrice);
    }
  }

  /// Заполняет атрибуты витрины (вкус, объем), если они указаны у товара.
  void _fillRetailAttributes(ReceiptRowData row, Ingredient ingredient) {
    final flavor = ingredient.attributes?['flavor']?.toString() ?? '';
    final volume = ingredient.attributes?['volume']?.toString() ?? '';
    if (flavor.isNotEmpty) {
      row.flavorController.text = flavor;
    }
    if (volume.isNotEmpty) {
      row.volumeController.text = volume;
    }
  }

  /// Очищает накладную от пустых строк перед сохранением в БД.
  void pruneEmptyRows() {
    items.removeWhere((r) => r.ingredient == null || r.quantity <= 0);
  }

  String _formatNum(double val) {
    if (val == val.truncateToDouble()) {
      return val.toInt().toString();
    }
    final str = val.toStringAsFixed(3);
    final trimmed = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }
}
