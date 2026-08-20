import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mynix_frontend/core/theme/app_logo_base64.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';

class DocumentPdfBuilder {
  static String formatPaymentStatus(String status) {
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

  static String formatPaymentMethod(String method) {
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

  static Future<Uint8List> buildPdfBytes(InventoryDocument doc, String currency) async {
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
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(pw.MemoryImage(logoBytes), width: 52, height: 38, fit: pw.BoxFit.contain),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('KRESO FLOW', style: pw.TextStyle(font: fontBlack, fontSize: 18, color: darkColor, letterSpacing: 0.5)),
                          pw.SizedBox(height: 2),
                          pw.Text('Система автоматизации общепита и торговли', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: grayColor)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(color: lightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)), border: pw.Border.all(color: borderLine, width: 0.5)),
                        child: pw.Text('$title #${doc.id}', style: pw.TextStyle(font: fontBold, fontSize: 11, color: orangeColor)),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('от $dateStr', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: grayColor)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: borderLine, thickness: 0.8),
              pw.SizedBox(height: 14),

              // Metadata Cards
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(color: lightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: borderLine, width: 0.5)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ПОСТАВЩИК / КОНТРАГЕНТ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: grayColor, letterSpacing: 0.5)),
                          pw.SizedBox(height: 4),
                          pw.Text(doc.supplierName ?? 'Не указан (Прямой приход)', style: pw.TextStyle(font: fontBold, fontSize: 12, color: darkColor)),
                          if (doc.invoiceNumber != null && doc.invoiceNumber!.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('Инвойс поставщика: № ${doc.invoiceNumber}', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: grayColor)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(color: lightBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: borderLine, width: 0.5)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ПАРАМЕТРЫ ОПЛАТЫ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: grayColor, letterSpacing: 0.5)),
                          pw.SizedBox(height: 4),
                          pw.Text(formatPaymentStatus(doc.paymentStatus), style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor)),
                          if (doc.paymentMethod.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Способ: ${formatPaymentMethod(doc.paymentMethod)}', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: grayColor)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // Items Table
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: borderLine, width: 0.5),
                  bottom: pw.BorderSide(color: borderLine, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.3),
                  4: const pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: tableHeaderBg, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6), child: pw.Text('№', style: pw.TextStyle(font: fontBold, fontSize: 9, color: grayColor))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8), child: pw.Text('Наименование позиции', style: pw.TextStyle(font: fontBold, fontSize: 9, color: grayColor))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8), child: pw.Text('Кол-во', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9, color: grayColor))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8), child: pw.Text('Цена ($currency)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9, color: grayColor))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8), child: pw.Text('Сумма ($currency)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9, color: grayColor))),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final it = entry.value;
                    final name = it.ingredientName ?? it.retailProductName ?? 'Позиция ${index + 1}';
                    final qty = it.quantity.toStringAsFixed(it.quantity.truncateToDouble() == it.quantity ? 0 : 2);
                    final price = it.pricePerUnit.toStringAsFixed(2);
                    final total = it.totalPrice.toStringAsFixed(2);

                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6), child: pw.Text('${index + 1}', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: grayColor))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text(name, style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkColor))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text(qty, textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: darkColor))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text(price, textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: darkColor))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: pw.Text('$total $currency', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkColor))),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 18),

              // Total Amount Box
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('ИТОГО К ОПЛАТЕ:  ', style: pw.TextStyle(font: fontBold, fontSize: 13, color: darkColor)),
                  pw.Text('${doc.totalAmount.toStringAsFixed(2)} $currency', style: pw.TextStyle(font: fontBlack, fontSize: 18, color: orangeColor)),
                ],
              ),
              pw.SizedBox(height: 48),

              // Signatures
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

              // Footer
              pw.Divider(color: borderLine, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Документ сформирован в экосистеме Kreso Flow', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: grayColor)),
                  pw.Text(dateStr, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: grayColor)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
