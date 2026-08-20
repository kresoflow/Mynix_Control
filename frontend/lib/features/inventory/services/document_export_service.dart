import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';
import 'package:mynix_frontend/features/inventory/services/export/document_pdf_builder.dart';
import 'package:mynix_frontend/features/inventory/services/export/document_text_builder.dart';
import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart' as export_helper;

class DocumentExportService {
  /// 📄 Генерация красивого бинарного PDF документа с логотипом Kreso Flow и поддержкой кириллицы
  static Future<Uint8List> generatePdfBytes(InventoryDocument doc, String currency) {
    return DocumentPdfBuilder.buildPdfBytes(doc, currency);
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
    final csvContent = DocumentTextBuilder.buildCsv(doc, currency);
    export_helper.downloadFile(
      'nakladnaya_${doc.id}.csv',
      csvContent,
      'text/csv;charset=utf-8',
    );
  }

  /// 🧾 Текстовый чек для WhatsApp / Telegram / TXT
  static String buildPlainText(InventoryDocument doc, String currency) {
    return DocumentTextBuilder.buildPlainText(doc, currency);
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
    return DocumentTextBuilder.buildJson(doc);
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
