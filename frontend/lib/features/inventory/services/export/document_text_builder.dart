import 'package:intl/intl.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'package:mynix_frontend/features/inventory/services/export/document_pdf_builder.dart';

class DocumentTextBuilder {
  /// CSV export with UTF-8 BOM for Excel Cyrillic support
  static String buildCsv(InventoryDocument doc, String currency) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal());
    final items = doc.items ?? [];

    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('ПРИХОДНАЯ НАКЛАДНАЯ #${doc.id};;;;');
    buffer.writeln('Дата: $dateStr;;;;');
    buffer.writeln('Поставщик: ${doc.supplierName ?? "-" };;;;');
    buffer.writeln('Условия оплаты: ${DocumentPdfBuilder.formatPaymentStatus(doc.paymentStatus)};;;;');
    buffer.writeln('');
    buffer.writeln('№;Наименование;Количество;Цена ($currency);Сумма ($currency)');

    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final name = (it.ingredientName ?? it.retailProductName ?? 'Товар').replaceAll(';', ',');
      final qty = it.quantity.toStringAsFixed(2);
      final price = it.pricePerUnit.toStringAsFixed(2);
      final total = it.totalPrice.toStringAsFixed(2);
      buffer.writeln('${i + 1};"$name";$qty;$price;$total');
    }

    buffer.writeln(';;;ИТОГО:;${doc.totalAmount.toStringAsFixed(2)}');
    return buffer.toString();
  }

  /// Plain Text for WhatsApp / Telegram
  static String buildPlainText(InventoryDocument doc, String currency) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal());
    final items = doc.items ?? [];

    final buffer = StringBuffer();
    buffer.writeln('📦 ПРИХОДНАЯ НАКЛАДНАЯ #${doc.id}');
    buffer.writeln('📅 $dateStr');
    buffer.writeln('🏢 Поставщик: ${doc.supplierName ?? "Не указан"}');
    if (doc.invoiceNumber != null && doc.invoiceNumber!.isNotEmpty) {
      buffer.writeln('📄 Инвойс: ${doc.invoiceNumber}');
    }
    buffer.writeln('💳 Оплата: ${DocumentPdfBuilder.formatPaymentStatus(doc.paymentStatus)}');
    buffer.writeln('──────────────────────────────');

    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final name = it.ingredientName ?? it.retailProductName ?? 'Позиция ${i + 1}';
      final qty = it.quantity.toStringAsFixed(it.quantity.truncateToDouble() == it.quantity ? 0 : 2);
      buffer.writeln('${i + 1}. $name — $qty шт × ${it.pricePerUnit.toStringAsFixed(2)} $currency = ${it.totalPrice.toStringAsFixed(2)} $currency');
    }

    buffer.writeln('──────────────────────────────');
    buffer.writeln('ИТОГО К ОПЛАТЕ: ${doc.totalAmount.toStringAsFixed(2)} $currency');

    return buffer.toString();
  }

  /// JSON Schema representation
  static Map<String, dynamic> buildJson(InventoryDocument doc) {
    return {
      'document_id': doc.id,
      'type': doc.type,
      'status': doc.status,
      'date': doc.date.toIso8601String(),
      'supplier': doc.supplierName,
      'invoice_number': doc.invoiceNumber,
      'payment_status': doc.paymentStatus,
      'paid_amount': doc.paidAmount,
      'payment_method': doc.paymentMethod,
      'total_amount': doc.totalAmount,
      'items': (doc.items ?? []).map((it) => {
        'ingredient_id': it.ingredientId,
        'ingredient_name': it.ingredientName,
        'retail_product_id': it.retailProductId,
        'retail_product_name': it.retailProductName,
        'quantity': it.quantity,
        'price_per_unit': it.pricePerUnit,
        'total_price': it.totalPrice,
      }).toList(),
    };
  }
}
