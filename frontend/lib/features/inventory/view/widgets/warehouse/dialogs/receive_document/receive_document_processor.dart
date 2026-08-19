import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/pos/repository/menu_repository.dart';
import 'receipt_row_data.dart';

class ReceiveDocumentProcessor {
  static double getConversionFactor(String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return 1.0;
    if (fromUnit == 'кг' && toUnit == 'г') return 1000.0;
    if (fromUnit == 'г' && toUnit == 'кг') return 0.001;
    if (fromUnit == 'л' && toUnit == 'мл') return 1000.0;
    if (fromUnit == 'мл' && toUnit == 'л') return 0.001;
    return 1.0;
  }

  static Future<void> saveDocument({
    required BuildContext context,
    required List<ReceiptRowData> items,
    required int? selectedSupplierId,
    required String invoiceNumber,
    required String reason,
    required int tabIndex,
    required int? categoryId,
    required bool complete,
    DateTime? documentDate,
    String paymentStatus = 'unpaid',
    double paidAmount = 0.0,
    String paymentMethod = 'cash',
  }) async {
    final repo = context.read<InventoryRepository>();
    final menuRepo = context.read<MenuRepository>();

    final List<Map<String, dynamic>> docItems = [];

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
          throw Exception(
            'Не выбрана категория для новых товаров ("${item.newName}"). Укажите категорию сверху.',
          );
        }
        String unitKey = 'pcs';
        switch (item.selectedUnit) {
          case 'кг': unitKey = 'kg'; break;
          case 'г': unitKey = 'g'; break;
          case 'л': unitKey = 'l'; break;
          case 'мл': unitKey = 'ml'; break;
          case 'шт':
          case 'порц':
          default:
            unitKey = 'pcs'; break;
        }

        if (tabIndex == 1) {
          final Map<String, dynamic> attributes = {};
          final flavor = item.flavorController.text.trim();
          final volume = item.volumeController.text.trim();
          if (flavor.isNotEmpty) attributes['Вкус'] = flavor;
          if (volume.isNotEmpty) attributes['Объем'] = '$volume ${item.selectedUnit}'.trim();

          finalRetailProductId = await menuRepo.createRetailProduct(
            name: item.newName.trim(),
            categoryId: categoryId,
            unit: unitKey,
            purchasePrice: item.price,
            sellingPrice: item.price,
            attributes: attributes.isNotEmpty ? attributes : null,
            initialStock: 0,
          );
        } else {
          finalIngredientId = await repo.createIngredient(
            name: item.newName.trim(),
            unit: unitKey,
            minStockAlert: 0,
            costPerUnit: item.price,
            categoryId: categoryId,
            initialStock: 0,
          );
        }
      } else {
        continue;
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
      'date': (documentDate ?? DateTime.now()).toIso8601String(),
      'supplier_id': selectedSupplierId,
      'invoice_number': invoiceNumber,
      'reason': reason,
      'payment_status': paymentStatus,
      'paid_amount': paidAmount,
      'payment_method': paymentMethod,
      'items': docItems,
      'status': complete ? 'completed' : 'draft',
    };

    if (context.mounted) {
      context.read<DocumentBloc>().add(CreateDocument(data));
      Navigator.of(context).pop();
    }
  }
}
