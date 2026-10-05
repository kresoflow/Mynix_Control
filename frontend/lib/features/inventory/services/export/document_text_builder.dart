import 'package:intl/intl.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/services/export/document_pdf_builder.dart';

class DocumentTextBuilder {
  static String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  /// CSV export with UTF-8 BOM for Excel Cyrillic support
  static String buildCsv(InventoryDocument doc, String currency) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal());
    final items = doc.items ?? [];
    final buffer = StringBuffer()..write('\uFEFF');

    if (doc.type == 'write_off') {
      buffer.writeln('АКТ СПИСАНИЯ #${doc.id};;;;');
      buffer.writeln('Дата: $dateStr;;;;');
      buffer.writeln(
        'Причина списания: ${doc.reason ?? "Порча / Просрочка"};;;;',
      );
      buffer.writeln('');
      buffer.writeln(
        '№;Наименование;Количество;Себестоимость ($currency);Сумма списания ($currency)',
      );

      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final name = (it.ingredientName ?? it.retailProductName ?? 'Товар')
            .replaceAll(';', ',');
        buffer.writeln(
          '${i + 1};"$name";${_fmt(it.quantity)};${it.pricePerUnit.toStringAsFixed(2)};${it.totalPrice.toStringAsFixed(2)}',
        );
      }
      buffer
          .writeln(';;;ИТОГО СПИСАНИЕ:;${doc.totalAmount.toStringAsFixed(2)}');
      return buffer.toString();
    }

    if (doc.type == 'inventory') {
      buffer.writeln('АКТ ИНВЕНТАРИЗАЦИИ #${doc.id};;;;;');
      buffer.writeln('Дата: $dateStr;;;;;');
      buffer.writeln('Тип: ${doc.reason ?? "Ревизия остатков склада"};;;;;');
      buffer.writeln('');
      buffer.writeln(
        '№;Наименование;Учет;Факт;Отклонение (кол-во);Сумма ($currency)',
      );

      double totalDiff = 0.0;
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final name = (it.ingredientName ?? it.retailProductName ?? 'Товар')
            .replaceAll(';', ',');
        final exp = it.expectedQuantity ?? it.quantity;
        final diff = it.quantity - exp;
        final diffAmount = diff * it.pricePerUnit;
        totalDiff += diffAmount;
        buffer.writeln(
          '${i + 1};"$name";${_fmt(exp)};${_fmt(it.quantity)};${_fmt(diff)};${diffAmount.toStringAsFixed(2)}',
        );
      }
      buffer
          .writeln(';;;;ИТОГОВОЕ РАСХОЖДЕНИЕ:;${totalDiff.toStringAsFixed(2)}');
      return buffer.toString();
    }

    // Default: Receipt (Приходная накладная)
    buffer.writeln('ПРИХОДНАЯ НАКЛАДНАЯ #${doc.id};;;;');
    buffer.writeln('Дата: $dateStr;;;;');
    buffer.writeln('Поставщик: ${doc.supplierName ?? "-"};;;;');
    buffer.writeln(
      'Условия оплаты: ${DocumentPdfBuilder.formatPaymentStatus(doc.paymentStatus)};;;;',
    );
    buffer.writeln('');
    buffer.writeln(
      '№;Наименование;Количество;Цена ($currency);Сумма ($currency)',
    );

    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final name = (it.ingredientName ?? it.retailProductName ?? 'Товар')
          .replaceAll(';', ',');
      buffer.writeln(
        '${i + 1};"$name";${_fmt(it.quantity)};${it.pricePerUnit.toStringAsFixed(2)};${it.totalPrice.toStringAsFixed(2)}',
      );
    }
    buffer.writeln(';;;ИТОГО К ОПЛАТЕ:;${doc.totalAmount.toStringAsFixed(2)}');
    return buffer.toString();
  }

  /// Plain Text for WhatsApp / Telegram / TXT
  static String buildPlainText(InventoryDocument doc, String currency) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal());
    final items = doc.items ?? [];
    final buffer = StringBuffer();

    if (doc.type == 'write_off') {
      buffer.writeln('АКТ СПИСАНИЯ #${doc.id}');
      buffer.writeln('Дата: $dateStr');
      buffer.writeln('Причина: ${doc.reason ?? "Не указана"}');
      buffer.writeln('──────────────────────────────');

      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final name =
            it.ingredientName ?? it.retailProductName ?? 'Позиция ${i + 1}';
        buffer.writeln(
          '${i + 1}. $name — ${_fmt(it.quantity)} шт × ${it.pricePerUnit.toStringAsFixed(2)} $currency = ${it.totalPrice.toStringAsFixed(2)} $currency',
        );
      }

      buffer.writeln('──────────────────────────────');
      buffer.writeln(
        'ИТОГО СПИСАНИЕ: ${doc.totalAmount.toStringAsFixed(2)} $currency',
      );
      return buffer.toString();
    }

    if (doc.type == 'inventory') {
      buffer.writeln('АКТ ИНВЕНТАРИЗАЦИИ #${doc.id}');
      buffer.writeln('Дата: $dateStr');
      buffer.writeln('Тип: ${doc.reason ?? "Слепая инвентаризация"}');
      buffer.writeln('──────────────────────────────');

      double totalDiff = 0.0;
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final name =
            it.ingredientName ?? it.retailProductName ?? 'Позиция ${i + 1}';
        final exp = it.expectedQuantity ?? it.quantity;
        final diff = it.quantity - exp;
        final diffAmount = diff * it.pricePerUnit;
        totalDiff += diffAmount;
        final diffStr = diff >= 0 ? '+${_fmt(diff)}' : _fmt(diff);
        buffer.writeln(
          '${i + 1}. $name: факт ${_fmt(it.quantity)} (учет ${_fmt(exp)}) | откл: $diffStr (${diffAmount.toStringAsFixed(2)} $currency)',
        );
      }

      buffer.writeln('──────────────────────────────');
      final totalDiffStr = totalDiff >= 0
          ? '+${totalDiff.toStringAsFixed(2)}'
          : totalDiff.toStringAsFixed(2);
      buffer.writeln('ИТОГОВОЕ РАСХОЖДЕНИЕ: $totalDiffStr $currency');
      return buffer.toString();
    }

    // Default: Receipt
    buffer.writeln('ПРИХОДНАЯ НАКЛАДНАЯ #${doc.id}');
    buffer.writeln('Дата: $dateStr');
    buffer.writeln('Поставщик: ${doc.supplierName ?? "Не указан"}');
    if (doc.invoiceNumber != null && doc.invoiceNumber!.isNotEmpty) {
      buffer.writeln('Инвойс: ${doc.invoiceNumber}');
    }
    buffer.writeln(
      'Оплата: ${DocumentPdfBuilder.formatPaymentStatus(doc.paymentStatus)}',
    );
    buffer.writeln('──────────────────────────────');

    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final name =
          it.ingredientName ?? it.retailProductName ?? 'Позиция ${i + 1}';
      buffer.writeln(
        '${i + 1}. $name — ${_fmt(it.quantity)} шт × ${it.pricePerUnit.toStringAsFixed(2)} $currency = ${it.totalPrice.toStringAsFixed(2)} $currency',
      );
    }

    buffer.writeln('──────────────────────────────');
    buffer.writeln(
      'ИТОГО К ОПЛАТЕ: ${doc.totalAmount.toStringAsFixed(2)} $currency',
    );
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
      'reason': doc.reason,
      'invoice_number': doc.invoiceNumber,
      'payment_status': doc.paymentStatus,
      'paid_amount': doc.paidAmount,
      'payment_method': doc.paymentMethod,
      'total_amount': doc.totalAmount,
      'items': (doc.items ?? [])
          .map(
            (it) => {
              'ingredient_id': it.ingredientId,
              'ingredient_name': it.ingredientName,
              'retail_product_id': it.retailProductId,
              'retail_product_name': it.retailProductName,
              'quantity': it.quantity,
              'expected_quantity': it.expectedQuantity,
              'price_per_unit': it.pricePerUnit,
              'total_price': it.totalPrice,
            },
          )
          .toList(),
    };
  }
}
