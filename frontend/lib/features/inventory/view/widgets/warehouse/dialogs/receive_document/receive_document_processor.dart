import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/document_event.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
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
    final List<Map<String, dynamic>> docItems = [];

    for (var item in items) {
      // If row is completely empty (no text and no ingredient), skip it
      final hasText = item.nameController.text.trim().isNotEmpty || item.newName.trim().isNotEmpty;
      if (item.ingredient == null && !hasText) {
        continue;
      }

      // Strictly enforce that every non-empty row references an existing catalog item
      if (item.ingredient == null) {
        final rowName = item.nameController.text.trim().isNotEmpty 
            ? item.nameController.text.trim() 
            : item.newName.trim();
        throw Exception(
          'Позиция "$rowName" не найдена в каталоге. Приход возможен только для существующих карточек товаров.',
        );
      }

      int? finalIngredientId;
      int? finalRetailProductId;

      final isRetail = item.ingredient!.attributes?['is_retail'] == true;
      if (isRetail) {
        finalRetailProductId = item.ingredient!.id;
      } else {
        finalIngredientId = item.ingredient!.id;
      }

      final factor = getConversionFactor(item.selectedUnit, item.ingredient!.unit);
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
      throw Exception('Нет товаров для прихода. Выберите хотя бы одну позицию из каталога.');
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
      if (complete) {
        try {
          context.read<IngredientBloc>().add(const LoadIngredients());
        } catch (_) {}
      }
      Navigator.of(context).pop();
    }
  }
}
