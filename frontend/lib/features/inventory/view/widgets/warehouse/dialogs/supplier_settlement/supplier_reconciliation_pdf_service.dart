import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mynix_frontend/core/theme/app_logo_base64.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/features/inventory/models/supplier_transaction.dart';
import 'package:mynix_frontend/features/inventory/services/export_helper_stub.dart'
    if (dart.library.html) 'package:mynix_frontend/features/inventory/services/export_helper_web.dart' as export_helper;

class SupplierReconciliationPdfService {
  static Future<Uint8List> generatePdfBytes(
    Supplier supplier,
    List<SupplierTransaction> transactions,
    String currency,
  ) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontBlack = await PdfGoogleFonts.robotoBlack();

    final logoBytes = AppLogoData.bytes;
    final nowStr = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    final orangeColor = PdfColor.fromHex('#FF6B00');
    final darkColor = PdfColor.fromHex('#111827');
    final grayColor = PdfColor.fromHex('#6B7280');
    final lightBg = PdfColor.fromHex('#F9FAFB');
    final tableHeaderBg = PdfColor.fromHex('#F3F4F6');
    final borderLine = PdfColor.fromHex('#E5E7EB');
    final greenColor = PdfColor.fromHex('#15803D');
    final redColor = PdfColor.fromHex('#DC2626');

    // Calculate totals
    double totalInvoices = 0.0;
    double totalPayments = 0.0;
    for (var t in transactions) {
      if (t.type == SupplierTransactionType.invoice || t.type == SupplierTransactionType.manualDebt) {
        totalInvoices += t.amount;
      } else if (t.type == SupplierTransactionType.payment) {
        totalPayments += t.amount;
      }
    }

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
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
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
                            style: pw.TextStyle(font: fontBlack, fontSize: 18, color: darkColor),
                          ),
                          pw.Text(
                            'Акт сверки взаиморасчетов',
                            style: pw.TextStyle(font: fontRegular, fontSize: 10, color: grayColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'АКТ СВЕРКИ',
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: darkColor),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Дата: $nowStr',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10, color: grayColor),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: borderLine, thickness: 1),
              pw.SizedBox(height: 12),

              // Supplier Info Card
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Поставщик: ${supplier.name}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: darkColor)),
                        if (supplier.contactInfo != null && supplier.contactInfo!.isNotEmpty)
                          pw.Text('Контакты: ${supplier.contactInfo}', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: grayColor)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          supplier.balance < 0
                              ? 'Долг: ${supplier.balance.abs().toStringAsFixed(2)} $currency'
                              : 'Баланс: ${supplier.balance.toStringAsFixed(2)} $currency',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            color: supplier.balance < 0 ? redColor : greenColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Table of Transactions
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: borderLine, width: 0.5),
                  bottom: pw.BorderSide(color: borderLine, width: 1),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FixedColumnWidth(75),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FixedColumnWidth(80),
                  4: const pw.FixedColumnWidth(80),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: tableHeaderBg),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('№', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Дата', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Операция / Документ', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Начислено (+)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Выплачено (-)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    ],
                  ),
                  ...transactions.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final t = entry.value;
                    final dateFormatted = DateFormat('dd.MM.yyyy HH:mm').format(t.date.toLocal());
                    final isDebt = t.type == SupplierTransactionType.invoice || t.type == SupplierTransactionType.manualDebt;
                    final desc = t.comment ?? t.type.label;

                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2), child: pw.Text('$idx', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: grayColor))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: pw.Text(dateFormatted, style: pw.TextStyle(font: fontRegular, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: pw.Text(desc, style: pw.TextStyle(font: fontRegular, fontSize: 9))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: pw.Text(
                            isDebt ? '${t.amount.toStringAsFixed(2)} $currency' : '-',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: fontBold, fontSize: 9, color: isDebt ? redColor : darkColor),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: pw.Text(
                            !isDebt ? '${t.amount.toStringAsFixed(2)} $currency' : '-',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: fontBold, fontSize: 9, color: !isDebt ? greenColor : darkColor),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Всего поставок: ${totalInvoices.toStringAsFixed(2)} $currency', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: darkColor)),
                      pw.SizedBox(height: 2),
                      pw.Text('Всего выплат: ${totalPayments.toStringAsFixed(2)} $currency', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: darkColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ИТОГОВОЕ САЛЬДО: ${supplier.balance < 0 ? "-" : "+"}${supplier.balance.abs().toStringAsFixed(2)} $currency',
                        style: pw.TextStyle(font: fontBlack, fontSize: 12, color: orangeColor),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('От лица Поставщика:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 28),
                      pw.Container(width: 180, height: 1, color: darkColor),
                      pw.SizedBox(height: 2),
                      pw.Text('подпись / ФИО', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: grayColor)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('От лица Заказчика (Бухгалтерия):', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      pw.SizedBox(height: 28),
                      pw.Container(width: 180, height: 1, color: darkColor),
                      pw.SizedBox(height: 2),
                      pw.Text('подпись / ФИО', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: grayColor)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: borderLine, thickness: 0.5),
              pw.Text('Kreso Flow • Документ сформирован автоматически', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: grayColor)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> downloadPdf(
    Supplier supplier,
    List<SupplierTransaction> transactions,
    String currency,
  ) async {
    final bytes = await generatePdfBytes(supplier, transactions, currency);
    export_helper.downloadBinaryFile(
      'akt_sverki_${supplier.id}.pdf',
      bytes,
      'application/pdf',
    );
  }

  static Future<void> printPdf(
    Supplier supplier,
    List<SupplierTransaction> transactions,
    String currency,
  ) async {
    final bytes = await generatePdfBytes(supplier, transactions, currency);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'akt_sverki_${supplier.id}.pdf',
    );
  }
}
