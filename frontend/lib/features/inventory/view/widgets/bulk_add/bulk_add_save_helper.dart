import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';

void performBulkSave({
  required BuildContext context,
  required int tabIndex,
  required int? targetCategoryId,
  required List<DishRowData> dishRows,
  required List<IngredientRowData> ingredientRows,
  required List<RetailRowData> retailRows,
  required List<CategoryRowData> categoryRows,
  String globalCategoryType = 'dish',
}) {
  if (tabIndex == 3) {
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
    if (bulkData.isNotEmpty) {
      context.read<CategoryBloc>().add(CreateCategoriesBulk(categories: bulkData));
    }
  } else if (tabIndex == 0) {
    int sortIndex = 0;
    for (var row in dishRows) {
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
            double p = 0.0;
            if (i < prices.length) {
               p = double.tryParse(prices[i]) ?? 0.0;
            } else if (prices.isNotEmpty) {
               p = double.tryParse(prices.last) ?? 0.0;
            }
            variations.add({'name': opts[i], 'price': p});
         }
         
         if (variations.isNotEmpty) {
            attributes = {'variations': variations};
            basePrice = variations.first['price'] as double;
         }
      } else {
         basePrice = double.tryParse(row.priceController.text) ?? 0.0;
      }

      context.read<MenuBloc>().add(
        CreateMenuItem(
          name: name,
          price: basePrice,
          category: (row.categoryId ?? targetCategoryId)?.toString() ?? '',
          sortOrder: sortIndex++,
          attributes: attributes,
        ),
      );
    }
  } else if (tabIndex == 2) {
    int sortIndex = 0;
    final items = <Map<String, dynamic>>[];
    for (var row in ingredientRows) {
      final name = row.nameController.text.trim();
      if (name.isEmpty) continue;

      final cost = double.tryParse(row.costController.text) ?? 0.0;
      final alert = double.tryParse(row.alertController.text) ?? 0.0;
      final stock = double.tryParse(row.stockController.text) ?? 0.0;

      items.add({
        'name': name,
        'unit': row.selectedUnit,
        'cost_per_unit': cost,
        'min_stock_alert': alert,
        'initial_stock': stock,
        'category_id': row.categoryId ?? targetCategoryId,
        'sort_order': sortIndex++,
        'barcode': row.sku,
      });
    }
    if (items.isNotEmpty) {
      context.read<IngredientBloc>().add(CreateIngredientsBulk(ingredients: items));
    }
  } else {
    for (var row in retailRows) {
      final baseName = row.nameController.text.trim();
      if (baseName.isEmpty) continue;

      final flavors = row.flavorController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final volumes = row.volumeController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final purchases = row.purchaseController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final sells = row.sellController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final stocks = row.stockController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final alerts = row.alertController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final barcodes = row.barcodeController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      if (flavors.isEmpty) flavors.add('');
      if (volumes.isEmpty) volumes.add('');

      String uLabel = '';
      if (row.selectedUnit == 'l') {
        uLabel = 'л';
      } else if (row.selectedUnit == 'ml') {
        uLabel = 'мл';
      } else if (row.selectedUnit == 'kg') {
        uLabel = 'кг';
      } else if (row.selectedUnit == 'g') {
        uLabel = 'г';
      } else if (row.selectedUnit == 'pcs') {
        uLabel = 'шт';
      }

      final bool hasOptions = !(flavors.length == 1 && flavors[0] == '' && volumes.length == 1 && volumes[0] == '');

      if (!hasOptions) {
        final purchase = purchases.isNotEmpty ? (double.tryParse(purchases.first) ?? 0.0) : 0.0;
        final sell = sells.isNotEmpty ? (double.tryParse(sells.first) ?? 0.0) : 0.0;
        final stock = stocks.isNotEmpty ? (double.tryParse(stocks.first) ?? 0.0) : 0.0;
        final alert = alerts.isNotEmpty ? (double.tryParse(alerts.first) ?? 0.0) : 0.0;
        final barcode = barcodes.isNotEmpty ? barcodes.first : null;

        context.read<MenuBloc>().add(
          CreateRetailProduct(
            name: baseName,
            categoryId: row.categoryId ?? targetCategoryId,
            unit: row.selectedUnit,
            purchasePrice: purchase,
            sellingPrice: sell,
            initialStock: stock,
            minStockAlert: alert,
            barcode: barcode,
          ),
        );
        continue;
      }

      for (int f = 0; f < flavors.length; f++) {
        final flavor = flavors[f];
        final groupName = baseName;

        final List<Map<String, dynamic>> variations = [];

        for (int v = 0; v < volumes.length; v++) {
          final volume = volumes[v];
          
          final List<String> nameParts = [baseName];
          if (flavor.isNotEmpty) nameParts.add(flavor);
          if (volume.isNotEmpty) nameParts.add('$volume $uLabel'.trim());
          
          final fullName = nameParts.join(' ');

          double getValue(List<String> list, int index) {
             if (list.isEmpty) return 0.0;
             if (index < list.length) return double.tryParse(list[index]) ?? 0.0;
             return double.tryParse(list.last) ?? 0.0;
          }

          final purchase = getValue(purchases, v);
          final sell = getValue(sells, v);
          final stock = getValue(stocks, v);
          final barcode = v < barcodes.length ? barcodes[v] : (barcodes.isNotEmpty ? barcodes.last : null);

          variations.add({
            'name': fullName,
            'unit': row.selectedUnit,
            'purchasePrice': purchase,
            'price': sell,
            'stock': stock,
            'barcode': barcode,
          });
        }

        context.read<MenuBloc>().add(
          CreateRetailProductGroup(
            name: groupName,
            categoryId: row.categoryId ?? targetCategoryId,
            flavor: flavor,
            variations: variations,
          ),
        );
      }
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Массовое добавление выполнено успешно!')),
  );
  Navigator.pop(context);
}
