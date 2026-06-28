import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:retail_os_frontend/features/pos/bloc/menu_bloc.dart';
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
      final price = double.tryParse(row.priceController.text) ?? 0.0;

      context.read<MenuBloc>().add(
        CreateMenuItem(
          name: name,
          price: price,
          category: targetCategoryId.toString(),
          sortOrder: sortIndex++,
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
      final sell = double.tryParse(row.sellController.text) ?? 0.0;
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

      if (flavors.isEmpty) flavors.add('');
      if (volumes.isEmpty) volumes.add('');

      for (var flavor in flavors) {
        for (var volume in volumes) {
          final Map<String, dynamic> attributes = {};
          
          if (flavor.isNotEmpty) {
            attributes['Вкус'] = flavor;
          }
          
          if (volume.isNotEmpty) {
            String uLabel = '';
            if (row.selectedUnit == 'l')
              uLabel = 'л';
            else if (row.selectedUnit == 'ml')
              uLabel = 'мл';
            else if (row.selectedUnit == 'kg')
              uLabel = 'кг';
            else if (row.selectedUnit == 'g')
              uLabel = 'г';
            else if (row.selectedUnit == 'pcs')
              uLabel = 'шт';
            
            attributes['Объем'] = '$volume $uLabel'.trim();
          }

          context.read<MenuBloc>().add(
            CreateRetailProduct(
              name: name,
              categoryId: targetCategoryId,
              unit: row.selectedUnit,
              purchasePrice: purchase,
              sellingPrice: sell,
              attributes: attributes.isNotEmpty ? attributes : null,
              initialStock: stock,
              sortOrder: sortIndex++,
            ),
          );
        }
      }
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Массовое добавление выполнено успешно!')),
  );
  Navigator.pop(context);
}
