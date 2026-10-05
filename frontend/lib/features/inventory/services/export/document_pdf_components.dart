// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kreso_frontend/core/theme/app_logo_base64.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';

// ==============================================================================
// 2. ВСПОМОГАТЕЛЬНЫЕ КОМПОНЕНТЫ И ФОРМАТТЕРЫ PDF
// ==============================================================================
/// [ИНВАРИАНТ] Визуальные блоки и форматтеры печатных документов PDF.
class DocumentPdfComponents {
  static const orange = PdfColor.fromInt(0xFFFF6B00);
  static const dark = PdfColor.fromInt(0xFF111827);
  static const gray = PdfColor.fromInt(0xFF6B7280);
  static const border = PdfColor.fromInt(0xFFE5E7EB);
  static const bg = PdfColor.fromInt(0xFFF9FAFB);

  static pw.Widget cell(
    String text,
    pw.Font font,
    double size,
    PdfColor color, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: size, color: color),
      ),
    );
  }

  static pw.Widget buildHeader({
    required String title,
    required int docId,
    required String dateStr,
    required pw.Font fontBlack,
    required pw.Font fontBold,
    required pw.Font fontReg,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Image(
              pw.MemoryImage(AppLogoData.bytes),
              width: 48,
              height: 36,
            ),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KRESO FLOW',
                  style: pw.TextStyle(
                    font: fontBlack,
                    fontSize: 16,
                    color: dark,
                  ),
                ),
                pw.Text(
                  'Система автоматизации общепита и торговли',
                  style: pw.TextStyle(
                    font: fontReg,
                    fontSize: 8,
                    color: gray,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: bg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: border, width: 0.5),
              ),
              child: pw.Text(
                '$title #$docId',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 11,
                  color: orange,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'от $dateStr',
              style: pw.TextStyle(
                font: fontReg,
                fontSize: 9,
                color: gray,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget buildMetadataCards({
    required InventoryDocument doc,
    required bool isReceipt,
    required bool isWriteOff,
    required String Function(String) formatPaymentStatus,
    required String Function(String) formatPaymentMethod,
    required pw.Font fontBold,
    required pw.Font fontReg,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: bg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: border, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isReceipt
                      ? 'ПОСТАВЩИК / КОНТРАГЕНТ'
                      : (isWriteOff ? 'ПРИЧИНА СПИСАНИЯ' : 'РЕВИЗИЯ СКЛАДА'),
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: gray),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  isReceipt
                      ? (doc.supplierName ?? 'Не указан')
                      : (doc.reason ?? 'Без указания причины'),
                  style:
                      pw.TextStyle(font: fontBold, fontSize: 11, color: dark),
                ),
                if (isReceipt &&
                    doc.invoiceNumber != null &&
                    doc.invoiceNumber!.isNotEmpty)
                  pw.Text(
                    'Инвойс: № ${doc.invoiceNumber}',
                    style:
                        pw.TextStyle(font: fontReg, fontSize: 8, color: gray),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: bg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: border, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isReceipt ? 'ПАРАМЕТРЫ ОПЛАТЫ' : 'ТИП ОПЕРАЦИИ',
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: gray),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  isReceipt
                      ? formatPaymentStatus(doc.paymentStatus)
                      : (isWriteOff
                          ? 'Списание сырья/товаров'
                          : 'Слепая инвентаризация'),
                  style:
                      pw.TextStyle(font: fontBold, fontSize: 11, color: dark),
                ),
                if (isReceipt && doc.paymentMethod.isNotEmpty)
                  pw.Text(
                    'Способ: ${formatPaymentMethod(doc.paymentMethod)}',
                    style:
                        pw.TextStyle(font: fontReg, fontSize: 8, color: gray),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget buildSignatures({
    required bool isReceipt,
    required pw.Font fontBold,
    required pw.Font fontReg,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              isReceipt
                  ? 'Сдал (Поставщик / Экспедитор):'
                  : 'Сдал (Ответственный сотрудник):',
              style: pw.TextStyle(font: fontBold, fontSize: 9, color: dark),
            ),
            pw.SizedBox(height: 24),
            pw.Container(width: 180, height: 1, color: dark),
            pw.SizedBox(height: 3),
            pw.Text(
              'подпись / расшифровка',
              style: pw.TextStyle(font: fontReg, fontSize: 7, color: gray),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              isReceipt
                  ? 'Принял (Кладовщик / Получатель):'
                  : 'Утвердил (Управляющий / Директор):',
              style: pw.TextStyle(font: fontBold, fontSize: 9, color: dark),
            ),
            pw.SizedBox(height: 24),
            pw.Container(width: 180, height: 1, color: dark),
            pw.SizedBox(height: 3),
            pw.Text(
              'подпись / расшифровка',
              style: pw.TextStyle(font: fontReg, fontSize: 7, color: gray),
            ),
          ],
        ),
      ],
    );
  }
}
