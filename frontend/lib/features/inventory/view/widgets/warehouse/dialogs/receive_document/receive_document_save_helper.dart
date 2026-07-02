import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/pos/repository/menu_repository.dart';

import 'receipt_row_data.dart';

Future<void> saveReceiveDocument({
  required BuildContext context,
  required bool mounted,
  required bool complete,
  required List<ReceiptRowData> items,
  required int tabIndex,
  required int? categoryId,
  required int? selectedSupplierId,
  required String invoiceNumber,
  required String reason,
  required void Function(bool) setSavingState,
}) async {
  if (items.isEmpty || items.every((item) => item.ingredient == null && item.newName.trim().isEmpty)) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Внимание'),
        content: const Text('Добавьте хотя бы одну позицию.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ОК'))],
      ),
    );
    return;
  }

  setSavingState(true);

  double getConversionFactor(String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return 1.0;
    if (fromUnit == 'кг' && toUnit == 'г') return 1000.0;
    if (fromUnit == 'г' && toUnit == 'кг') return 0.001;
    if (fromUnit == 'л' && toUnit == 'мл') return 1000.0;
    if (fromUnit == 'мл' && toUnit == 'л') return 0.001;
    return 1.0;
  }

  try {
    final repo = context.read<InventoryRepository>();
    final menuRepo = context.read<MenuRepository>();

    List<Map<String, dynamic>> docItems = [];

    for (var item in items) {
      int? finalIngredientId;
      int? finalRetailProductId;

      if (item.ingredient != null) {
        final isRetail = item.ingredient!.attributes?['is_retail'] == true;
        if (isRetail) {
          finalRetailProductId = item.ingredient!.id;
        } else {
          finalIngredientId = item.ingredient!.id;
        }
      } else if (item.newName.trim().isNotEmpty) {
        if (categoryId == null) {
          throw Exception('Не выбрана категория для новых товаров ("${item.newName}"). Укажите категорию сверху.');
        }
        if (item.isNew) {
          final isRetail = tabIndex == 1;
          if (isRetail) {
            final attributes = <String, String>{};
            final flavor = item.flavorController.text.trim();
            final volume = item.volumeController.text.trim();
            if (flavor.isNotEmpty) attributes['Вкус'] = flavor;
            if (volume.isNotEmpty) attributes['Объем'] = '$volume ${item.selectedUnit}'.trim();

            await menuRepo.createRetailProduct(
              name: item.newName.trim(),
              categoryId: categoryId,
              unit: item.selectedUnit,
              purchasePrice: item.price,
              sellingPrice: item.price,
              attributes: attributes.isNotEmpty ? attributes : null,
              initialStock: 0,
            );
            finalRetailProductId = DateTime.now().millisecondsSinceEpoch;
          } else {
            await repo.createIngredient(
              name: item.newName.trim(),
              unit: item.selectedUnit,
              minStockAlert: 0,
              costPerUnit: item.price,
              categoryId: categoryId,
              initialStock: 0,
            );
            finalIngredientId = DateTime.now().millisecondsSinceEpoch;
          }
        }
      } else {
        continue; // skip empty rows
      }

      double factor = 1.0;
      if (item.ingredient != null) {
        factor = getConversionFactor(item.selectedUnit, item.ingredient!.unit);
      }

      final dbQuantity = item.quantity * factor;
      final dbPricePerUnit = item.price / factor;

      docItems.add({
        'ingredient_id': finalIngredientId,
        'retail_product_id': finalRetailProductId,
        'quantity': dbQuantity,
        'price_per_unit': dbPricePerUnit,
        'total_price': dbQuantity * dbPricePerUnit,
      });
    }

    if (docItems.isEmpty) {
      throw Exception('Нет товаров для прихода');
    }

    final data = {
      'type': 'receipt',
      'supplier_id': selectedSupplierId,
      'invoice_number': invoiceNumber,
      'reason': reason,
      'items': docItems,
      'status': complete ? 'completed' : 'draft',
    };

    if (mounted) {
      context.read<DocumentBloc>().add(CreateDocument(data));
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      setSavingState(false);
    }
  }
}
