import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';

void performBulkSave({
  required BuildContext context,
  required int tabIndex,
  required int? targetCategoryId,
  required List<DishRowData> dishRows,
  required List<IngredientRowData> ingredientRows,
  required List<RetailRowData> retailRows,
}) {
  if (tabIndex == 0) {
    if (targetCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите категорию!')));
      return;
    }
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
         
         List<Map<String, dynamic>> variations = [];
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
          category: targetCategoryId.toString(),
          sortOrder: sortIndex++,
          attributes: attributes,
        ),
      );
    }
  } else if (tabIndex == 2) {
    if (targetCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите категорию!')));
      return;
    }
    int sortIndex = 0;
    for (var row in ingredientRows) {
      final name = row.nameController.text.trim();
      if (name.isEmpty) continue;

      final cost = double.tryParse(row.costController.text) ?? 0.0;
      final alert = double.tryParse(row.alertController.text) ?? 0.0;
      final stock = double.tryParse(row.stockController.text) ?? 0.0;

      context.read<IngredientBloc>().add(
        CreateIngredient(
          name: name,
          unit: row.selectedUnit,
          costPerUnit: cost,
          minStockAlert: alert,
          initialStock: stock,
          categoryId: targetCategoryId,
          sortOrder: sortIndex++,
        ),
      );
    }
  } else {
    if (targetCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите категорию!')));
      return;
    }

    int sortIndex = 0;
    for (var row in retailRows) {
      final name = row.nameController.text.trim();
      if (name.isEmpty) continue;

      final purchase = double.tryParse(row.purchaseController.text) ?? 0.0;
      final stock = double.tryParse(row.stockController.text) ?? 0.0;

      final flavors = row.flavorController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final volumes = row.volumeController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final prices = row.sellController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      Map<String, dynamic>? attributes;
      double baseSellingPrice = 0.0;

      List<Map<String, dynamic>> modifierGroups = [];
      if (flavors.isNotEmpty) {
        modifierGroups.add({
          'name': 'Вкус',
          'required': true,
          'max_selections': 1,
          'modifiers': flavors.map((f) => {'name': f, 'price': 0.0}).toList(),
        });
      }

      List<Map<String, dynamic>> variations = [];
      if (volumes.isNotEmpty) {
        String uLabel = '';
        if (row.selectedUnit == 'l') uLabel = 'л';
        else if (row.selectedUnit == 'ml') uLabel = 'мл';
        else if (row.selectedUnit == 'kg') uLabel = 'кг';
        else if (row.selectedUnit == 'g') uLabel = 'г';
        else if (row.selectedUnit == 'pcs') uLabel = 'шт';

        for (int i = 0; i < volumes.length; i++) {
          double p = 0.0;
          if (i < prices.length) {
            p = double.tryParse(prices[i]) ?? 0.0;
          } else if (prices.isNotEmpty) {
            p = double.tryParse(prices.last) ?? 0.0;
          }
          variations.add({'name': '${volumes[i]} $uLabel'.trim(), 'price': p});
        }
      } else {
        baseSellingPrice = double.tryParse(row.sellController.text) ?? 0.0;
      }

      if (modifierGroups.isNotEmpty || variations.isNotEmpty) {
        attributes = {};
        if (variations.isNotEmpty) {
           attributes['variations'] = variations;
           baseSellingPrice = variations.first['price'] as double;
        }
        if (modifierGroups.isNotEmpty) attributes['modifier_groups'] = modifierGroups;
      }

      context.read<MenuBloc>().add(
        CreateRetailProduct(
          name: name,
          categoryId: targetCategoryId,
          unit: row.selectedUnit,
          purchasePrice: purchase,
          sellingPrice: baseSellingPrice,
          attributes: attributes,
          initialStock: stock,
          sortOrder: sortIndex++,
        ),
      );
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Массовое добавление выполнено успешно!')),
  );
  Navigator.pop(context);
}
