import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mynix_frontend/core/theme/app_logo_base64.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart' as export_helper;

class DocumentExportService {
  static String _formatPaymentStatus(String status) {
    switch (status) {
      case 'unpaid':
        return 'В долг (Постоплата)';
      case 'paid':
        return 'Оплачено сразу';
      case 'partial':
        return 'Частичная оплата';
      default:
        return status;
    }
  }

  static String _formatPaymentMethod(String method) {
    switch (method) {
      case 'cash':
        return 'Наличные';
      case 'card':
        return 'Банковская карта';
      case 'bank_transfer':
        return 'Расчетный счет / Перевод';
      default:
        return method;
    }
  }

  /// 📄 Генерация красивого бинарного PDF документа с логотипом Kreso Flow и поддержкой кириллицы
  static Future<Uint8List> generatePdfBytes(InventoryDocument doc, String currency) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontBlack = await PdfGoogleFonts.robotoBlack();

    final logoBytes = AppLogoData.bytes;

    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal());
    final isReceipt = doc.type == 'receipt';
    final title = isReceipt ? 'ПРИХОДНАЯ НАКЛАДНАЯ' : 'АКТ СПИСАНИЯ';
    final items = doc.items ?? [];

    final orangeColor = PdfColor.fromHex('#FF6B00');
    final darkColor = PdfColor.fromHex('#111827');
    final grayColor = PdfColor.fromHex('#6B7280');
    final lightBg = PdfColor.fromHex('#F9FAFB');
    final tableHeaderBg = PdfColor.fromHex('#F3F4F6');
    final borderLine = PdfColor.fromHex('#E5E7EB');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Brand Header (Logo + Meta)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(
                        pw.MemoryImage(logoBytes),
                        width: 52,
                        height: 38,
                        fit: pw.BoxFit.contain,
                      ),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'KRESO FLOW',
                            style: pw.TextStyle(
                              font: fontBlack,
                              fontSize: 18,
                              color: darkColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Автоматизация и складской учет',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 10,
                              color: grayColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '$title #${doc.id}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: darkColor,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Дата: $dateStr',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 11,
                          color: grayColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: doc.status == 'completed'
                              ? PdfColor.fromHex('#DCFCE7')
                              : PdfColor.fromHex('#FEF3C7'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          doc.status == 'completed' ? 'ПРОВЕДЕН' : 'ЧЕРНОВИК',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: doc.status == 'completed'
                                ? PdfColor.fromHex('#15803D')
                                : PdfColor.fromHex('#B45309'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: borderLine, thickness: 1),
              pw.SizedBox(height: 14),

              // 2. Info Block (Supplier, Invoice, Payment Terms)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'Поставщик: ',
                          style: pw.TextStyle(font: fontBold, fontSize: 12, color: darkColor),
                        ),
                        pw.Text(
                          doc.supplierName ?? 'Не указан',
                          style: pw.TextStyle(font: fontRegular, fontSize: 12, color: darkColor),
                        ),
                      ],
                    ),
                    if (doc.invoiceNumber != null && doc.invoiceNumber!.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Номер накладной поставщика: ',
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: darkColor),
                          ),
                          pw.Text(
                            doc.invoiceNumber!,
                            style: pw.TextStyle(font: fontRegular, fontSize: 12, color: darkColor),
                          ),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Условия расчёта: ',
                          style: pw.TextStyle(font: fontBold, fontSize: 12, color: darkColor),
                        ),
                        pw.Text(
                          '${_formatPaymentStatus(doc.paymentStatus)} (${_formatPaymentMethod(doc.paymentMethod)})',
                          style: pw.TextStyle(font: fontRegular, fontSize: 12, color: darkColor),
                        ),
                      ],
                    ),
                    if (doc.reason != null && doc.reason!.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Примечание: ',
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: darkColor),
                          ),
                          pw.Text(
                            doc.reason!,
                            style: pw.TextStyle(font: fontRegular, fontSize: 12, color: darkColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // 3. Table of Items
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: borderLine, width: 0.5),
                  bottom: pw.BorderSide(color: borderLine, width: 1),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(32),
                  1: const pw.FlexColumnWidth(5),
                  2: const pw.FixedColumnWidth(70),
                  3: const pw.FixedColumnWidth(95),
                  4: const pw.FixedColumnWidth(105),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: tableHeaderBg,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('№', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Наименование', style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Кол-во', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Цена закупки', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Сумма', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                      ),
                    ],
                  ),
                  // Item Rows
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final it = entry.value;
                    final name = it.ingredientName ?? it.retailProductName ?? 'Товар #${it.id}';
                    final qty = it.quantity.toStringAsFixed(it.quantity.truncateToDouble() == it.quantity ? 0 : 2);
                    final price = it.pricePerUnit.toStringAsFixed(2);
                    final total = it.totalPrice.toStringAsFixed(2);

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: pw.Text('$idx', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 11, color: grayColor)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: pw.Text(name, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: pw.Text(qty, textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontRegular, fontSize: 11, color: darkColor)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: pw.Text('$price $currency', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontRegular, fontSize: 11, color: grayColor)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: pw.Text('$total $currency', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 18),

              // 4. Total Amount Box
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'ИТОГО К ОПЛАТЕ:  ',
                    style: pw.TextStyle(font: fontBold, fontSize: 13, color: darkColor),
                  ),
                  pw.Text(
                    '${doc.totalAmount.toStringAsFixed(2)} $currency',
                    style: pw.TextStyle(font: fontBlack, fontSize: 18, color: orangeColor),
                  ),
                ],
              ),
              pw.SizedBox(height: 48),

              // 5. Signatures Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Сдал (Поставщик / Экспедитор):', style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkColor)),
                      pw.SizedBox(height: 32),
                      pw.Container(width: 200, height: 1, color: darkColor),
                      pw.SizedBox(height: 4),
                      pw.Text('подпись / расшифровка', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: grayColor)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Принял (Кладовщик / Получатель):', style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkColor)),
                      pw.SizedBox(height: 32),
                      pw.Container(width: 200, height: 1, color: darkColor),
                      pw.SizedBox(height: 4),
                      pw.Text('подпись / расшифровка', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: grayColor)),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // 6. Corporate Footer
              pw.Divider(color: borderLine, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Документ сформирован в экосистеме Kreso Flow',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8, color: grayColor),
                  ),
                  pw.Text(
                    dateStr,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8, color: grayColor),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// 📥 Прямое скачивание файла .PDF в один клик
  static Future<void> downloadPdf(InventoryDocument doc, String currency) async {
    final pdfBytes = await generatePdfBytes(doc, currency);
    export_helper.downloadBinaryFile(
      'nakladnaya_${doc.id}.pdf',
      pdfBytes,
      'application/pdf',
    );
  }

  /// 🖨️ Прямая печать через системный диалог печати
  static Future<void> printDocument(InventoryDocument doc, String currency) async {
    final pdfBytes = await generatePdfBytes(doc, currency);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'nakladnaya_${doc.id}.pdf',
    );
  }

  /// 📊 Экспорт в Excel (.csv с поддержкой UTF-8 BOM для русской кириллицы)
  static void exportExcel(InventoryDocument doc, String currency) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal());
    final items = doc.items ?? [];

    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('ПРИХОДНАЯ НАКЛАДНАЯ #${doc.id};;;;');
    buffer.writeln('Дата: $dateStr;;;;');
    buffer.writeln('Поставщик: ${doc.supplierName ?? "-" };;;;');
    buffer.writeln('Условия оплаты: ${_formatPaymentStatus(doc.paymentStatus)};;;;');
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

    export_helper.downloadFile(
      'nakladnaya_${doc.id}.csv',
      buffer.toString(),
      'text/csv;charset=utf-8',
    );
  }

  /// 🧾 Текстовый чек для WhatsApp / Telegram / TXT
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
    buffer.writeln('💳 Оплата: ${_formatPaymentStatus(doc.paymentStatus)}');
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

  /// 📋 Копировать как текст
  static Future<void> copyAsText(InventoryDocument doc, String currency) async {
    final text = buildPlainText(doc, currency);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 📄 Скачать как TXT
  static void exportTxt(InventoryDocument doc, String currency) {
    final text = buildPlainText(doc, currency);
    export_helper.downloadFile(
      'nakladnaya_${doc.id}.txt',
      text,
      'text/plain;charset=utf-8',
    );
  }

  /// ⚙️ Экспорт JSON
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

  static Future<void> copyAsJson(InventoryDocument doc) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(buildJson(doc));
    await Clipboard.setData(ClipboardData(text: jsonStr));
  }

  static void exportJson(InventoryDocument doc) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(buildJson(doc));
    export_helper.downloadFile(
      'nakladnaya_${doc.id}.json',
      jsonStr,
      'application/json;charset=utf-8',
    );
  }
}
