// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'document_pdf_components.dart';
import 'document_pdf_table.dart';

// ==============================================================================
// 2. БИЛДЕР PDF ДОКУМЕНТОВ
// ==============================================================================
/// [ИНВАРИАНТ] Генератор бинарных PDF накладных, актов списания и ревизии.
class DocumentPdfBuilder {
  static String formatPaymentStatus(String s) {
    switch (s) {
      case 'unpaid':
        return 'В долг (Постоплата)';
      case 'paid':
        return 'Оплачено сразу';
      case 'partial':
        return 'Частичная оплата';
      default:
        return s;
    }
  }

  static String formatPaymentMethod(String m) {
    switch (m) {
      case 'cash':
        return 'Наличные';
      case 'card':
        return 'Банковская карта';
      case 'bank_transfer':
        return 'Расчетный счет / Перевод';
      default:
        return m;
    }
  }

  static Future<Uint8List> buildPdfBytes(
    InventoryDocument doc,
    String currency,
  ) async {
    final pdf = pw.Document();
    final fontReg = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontBlack = await PdfGoogleFonts.robotoBlack();

    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(doc.date.toLocal());
    final isReceipt = doc.type == 'receipt';
    final isWriteOff = doc.type == 'write_off';
    final isInventory = doc.type == 'inventory';
    final title = isReceipt
        ? 'ПРИХОДНАЯ НАКЛАДНАЯ'
        : (isWriteOff
            ? 'АКТ СПИСАНИЯ'
            : (isInventory ? 'АКТ ИНВЕНТАРИЗАЦИИ' : 'ДОКУМЕНТ СКЛАДА'));
    final items = doc.items ?? [];

    double totalDiff = 0.0;
    if (isInventory) {
      for (final it in items) {
        final exp = it.expectedQuantity ?? it.quantity;
        totalDiff += (it.quantity - exp) * it.pricePerUnit;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        theme: pw.ThemeData.withFont(base: fontReg, bold: fontBold),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            DocumentPdfComponents.buildHeader(
              title: title,
              docId: doc.id,
              dateStr: dateStr,
              fontBlack: fontBlack,
              fontBold: fontBold,
              fontReg: fontReg,
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: DocumentPdfComponents.border, thickness: 0.8),
            pw.SizedBox(height: 10),
            DocumentPdfComponents.buildMetadataCards(
              doc: doc,
              isReceipt: isReceipt,
              isWriteOff: isWriteOff,
              formatPaymentStatus: formatPaymentStatus,
              formatPaymentMethod: formatPaymentMethod,
              fontBold: fontBold,
              fontReg: fontReg,
            ),
            pw.SizedBox(height: 14),
            DocumentPdfTable.build(
              doc: doc,
              currency: currency,
              isReceipt: isReceipt,
              isWriteOff: isWriteOff,
              isInventory: isInventory,
              fontBold: fontBold,
              fontReg: fontReg,
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  isReceipt
                      ? 'ИТОГО К ОПЛАТЕ:  '
                      : (isWriteOff ? 'ИТОГО СПИСАНИЕ:  ' : 'РАСХОЖДЕНИЕ:  '),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: DocumentPdfComponents.dark,
                  ),
                ),
                pw.Text(
                  isInventory
                      ? '${totalDiff >= 0 ? '+' : ''}${totalDiff.toStringAsFixed(2)} $currency'
                      : '${doc.totalAmount.toStringAsFixed(2)} $currency',
                  style: pw.TextStyle(
                    font: fontBlack,
                    fontSize: 16,
                    color: isWriteOff
                        ? PdfColors.red
                        : DocumentPdfComponents.orange,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 36),
            DocumentPdfComponents.buildSignatures(
              isReceipt: isReceipt,
              fontBold: fontBold,
              fontReg: fontReg,
            ),
            pw.Spacer(),
            pw.Divider(color: DocumentPdfComponents.border, thickness: 0.5),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Документ сформирован в экосистеме Kreso Flow',
                  style: pw.TextStyle(
                    font: fontReg,
                    fontSize: 7,
                    color: DocumentPdfComponents.gray,
                  ),
                ),
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                    font: fontReg,
                    fontSize: 7,
                    color: DocumentPdfComponents.gray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
