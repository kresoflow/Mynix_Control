// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Снимок состояния ритейл-товара (Poka-Yoke)
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/retail_product_snapshot.dart
// ==============================================================================

import 'dart:convert';

/// [ИНВАРИАНТ] Снимок исходного состояния товара витрины для Poka-Yoke валидации.
///
/// Предотвращает ложные алерты о несохраненных изменениях при закрытии диалога.
class RetailProductSnapshot {
  final String name;
  final String flavor;
  final String volume;
  final String sortOrder;
  final String price;
  final String barcode;
  final int? categoryId;
  final String stockUnit;
  final String displayUnit;
  final String? icon;
  final String variationsJson;

  const RetailProductSnapshot({
    required this.name,
    required this.flavor,
    required this.volume,
    required this.sortOrder,
    required this.price,
    required this.barcode,
    required this.categoryId,
    required this.stockUnit,
    required this.displayUnit,
    required this.icon,
    required this.variationsJson,
  });

  bool isDirty({
    required bool isEditing,
    required String currentName,
    required String currentFlavor,
    required String currentVolume,
    required String currentSortOrder,
    required String currentPrice,
    required String currentBarcode,
    required int? currentCategoryId,
    required String currentStockUnit,
    required String currentDisplayUnit,
    required String? currentIcon,
    required List<Map<String, dynamic>> currentVariations,
  }) {
    if (!isEditing) {
      return currentName.isNotEmpty ||
          currentFlavor.isNotEmpty ||
          currentVolume.isNotEmpty ||
          currentSortOrder.isNotEmpty ||
          currentPrice.isNotEmpty ||
          currentBarcode.isNotEmpty ||
          currentVariations.isNotEmpty ||
          currentCategoryId != categoryId ||
          currentStockUnit != stockUnit ||
          currentDisplayUnit != displayUnit ||
          currentIcon != icon;
    }

    if (currentName != name) return true;
    if (currentFlavor != flavor) return true;
    if (currentSortOrder != sortOrder) return true;
    if (currentBarcode != barcode) return true;
    if (currentCategoryId != categoryId) return true;
    if (currentStockUnit != stockUnit) return true;
    if (currentDisplayUnit != displayUnit) return true;
    if (currentIcon != icon) return true;

    if (currentVariations.isNotEmpty || variationsJson != '[]') {
      return jsonEncode(currentVariations) != variationsJson;
    }

    if (currentVolume != volume) return true;
    if (currentPrice != price) return true;

    return false;
  }
}
