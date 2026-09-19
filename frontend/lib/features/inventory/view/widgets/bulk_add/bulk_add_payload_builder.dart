import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';

const _unitLabels = {'l': 'л', 'ml': 'мл', 'kg': 'кг', 'g': 'г', 'pcs': 'шт'};

List<Map<String, dynamic>> buildCategoryPayload({
  required List<CategoryRowData> categoryRows,
  required int? targetCategoryId,
  required String globalCategoryType,
}) {
  int defaultSortOrder = 1;
  final bulkData = <Map<String, dynamic>>[];
  for (final row in categoryRows) {
    final name = row.nameController.text.trim();
    if (name.isEmpty) continue;

    int sortOrder = defaultSortOrder;
    final customSortRaw = row.sortOrderController.text.trim();
    if (customSortRaw.isNotEmpty) {
      sortOrder = int.tryParse(customSortRaw) ?? defaultSortOrder;
    }

    String? iconPayload;
    if (row.selectedIcon != null && row.selectedIcon!.isNotEmpty) {
      iconPayload = 'icon:${row.selectedIcon}';
    }

    bulkData.add({
      'name': name,
      'category_type': globalCategoryType,
      'parent_id': targetCategoryId,
      'sort_order': sortOrder,
      'is_visible': true,
      'icon': iconPayload,
    });
    defaultSortOrder++;
  }
  return bulkData;
}

List<Map<String, dynamic>> buildDishPayload({
  required List<DishRowData> dishRows,
  required int? targetCategoryId,
}) {
  int sortIndex = 0;
  final items = <Map<String, dynamic>>[];
  for (final row in dishRows) {
    final name = row.nameController.text.trim();
    if (name.isEmpty) continue;

    final optionsRaw = row.optionsController.text.trim();
    Map<String, dynamic>? attributes;
    double basePrice = 0.0;

    if (optionsRaw.isNotEmpty) {
      final opts = optionsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final prices = row.priceController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final List<Map<String, dynamic>> variations = [];
      for (int i = 0; i < opts.length; i++) {
        final p = i < prices.length
            ? (double.tryParse(prices[i]) ?? 0.0)
            : (prices.isNotEmpty ? (double.tryParse(prices.last) ?? 0.0) : 0.0);
        variations.add({'name': opts[i], 'price': p});
      }

      if (variations.isNotEmpty) {
        attributes = {'variations': variations};
        basePrice = (variations.first['price'] as num).toDouble();
      }
    } else {
      basePrice = double.tryParse(row.priceController.text) ?? 0.0;
    }

    final catId = row.categoryId ?? targetCategoryId;
    items.add({
      'name': name,
      'price': basePrice,
      'category_id': (catId == null || catId == 0) ? null : catId,
      'sort_order': sortIndex++,
      if (attributes != null) 'attributes': attributes,
      'is_available': true,
      'type': 'dish',
    });
  }
  return items;
}

List<Map<String, dynamic>> buildIngredientPayload({
  required List<IngredientRowData> ingredientRows,
  required int? targetCategoryId,
  required List<MenuCategory> ingredientCategories,
  required List<Ingredient> existingIngredients,
}) {
  final Map<int, int> categorySeqCounters = {};
  int sortIndex = 0;
  final items = <Map<String, dynamic>>[];

  for (final row in ingredientRows) {
    final name = row.nameController.text.trim();
    if (name.isEmpty) continue;

    final cost = double.tryParse(row.costController.text) ?? 0.0;
    final effectiveCatId = row.categoryId ?? targetCategoryId;

    String? sku = row.sku;
    if (sku == null || sku.trim().isEmpty) {
      if (effectiveCatId != null) {
        final catIndex = ingredientCategories.indexWhere((c) => c.id == effectiveCatId);
        final prefix = catIndex >= 0 ? (catIndex + 1) * 10 : 10;
        final existingInCat = existingIngredients.where((i) => i.categoryId == effectiveCatId).length;
        final currentBatchCount = categorySeqCounters[effectiveCatId] ?? 0;
        final nextSeq = existingInCat + currentBatchCount + 1;
        categorySeqCounters[effectiveCatId] = currentBatchCount + 1;
        sku = '$prefix-${nextSeq.toString().padLeft(2, '0')}';
      }
    }

    items.add({
      'name': name,
      'unit': row.selectedUnit,
      'cost_per_unit': cost,
      'min_stock_alert': 0.0,
      'initial_stock': 0.0,
      'category_id': effectiveCatId,
      'sort_order': sortIndex++,
      'barcode': sku,
    });
  }
  return items;
}

List<Map<String, dynamic>> buildRetailPayload({
  required List<RetailRowData> retailRows,
  required int? targetCategoryId,
}) {
  int sortIndex = 0;
  final items = <Map<String, dynamic>>[];

  for (final row in retailRows) {
    final baseName = row.nameController.text.trim();
    if (baseName.isEmpty) continue;

    final flavors = row.flavorController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final volumes = row.volumeController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final sells = row.sellController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final barcodes = row.barcodeController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (flavors.isEmpty) flavors.add('');
    if (volumes.isEmpty) volumes.add('');
    final uLabel = _unitLabels[row.selectedUnit] ?? '';
    final bool hasOptions = !(flavors.length == 1 && flavors[0] == '' && volumes.length == 1 && volumes[0] == '');

    if (!hasOptions) {
      items.add({
        'name': baseName,
        'category_id': row.categoryId ?? targetCategoryId,
        'unit': row.selectedUnit,
        'purchase_price': 0.0,
        'selling_price': sells.isNotEmpty ? (double.tryParse(sells.first) ?? 0.0) : 0.0,
        'initial_stock': 0.0,
        'min_stock_alert': 0.0,
        'barcode': barcodes.isNotEmpty ? barcodes.first : null,
        'sort_order': sortIndex++,
      });
      continue;
    }

    for (final flavor in flavors) {
      final List<Map<String, dynamic>> variations = [];
      for (int v = 0; v < volumes.length; v++) {
        final volume = volumes[v];
        final nameParts = [baseName, if (flavor.isNotEmpty) flavor, if (volume.isNotEmpty) '$volume $uLabel'.trim()];
        final sell = v < sells.length ? (double.tryParse(sells[v]) ?? 0.0) : (sells.isNotEmpty ? (double.tryParse(sells.last) ?? 0.0) : 0.0);
        final barcode = v < barcodes.length ? barcodes[v] : (barcodes.isNotEmpty ? barcodes.last : null);

        variations.add({
          'name': nameParts.join(' '),
          'unit': row.selectedUnit,
          'purchase_price': 0.0,
          'purchasePrice': 0.0,
          'price': sell,
          'selling_price': sell,
          'initial_stock': 0.0,
          'barcode': barcode,
        });
      }

      final firstSell = variations.isNotEmpty ? (variations.first['price'] as num).toDouble() : 0.0;

      items.add({
        'name': baseName,
        'category_id': row.categoryId ?? targetCategoryId,
        'unit': row.selectedUnit,
        'purchase_price': 0.0,
        'selling_price': firstSell,
        'initial_stock': 0.0,
        'min_stock_alert': 0.0,
        'sort_order': sortIndex++,
        'attributes': {
          'icon': 'package',
          if (flavor.isNotEmpty) 'flavor': flavor,
          'variations': variations,
        },
      });
    }
  }
  return items;
}

