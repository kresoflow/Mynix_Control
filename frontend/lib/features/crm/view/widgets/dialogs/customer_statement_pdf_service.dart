import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mynix_frontend/core/theme/app_logo_base64.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/models/customer_transaction.dart';
import 'package:mynix_frontend/features/inventory/services/export_helper_stub.dart'
    if (dart.library.html) 'package:mynix_frontend/features/inventory/services/export_helper_web.dart' as export_helper;

class CustomerStatementPdfService {
  static Future<Uint8List> generatePdfBytes(
    Customer customer,
    List<CustomerTransaction> transactions,
    String currency,
  ) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final logoBytes = AppLogoData.bytes;
    final nowStr = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    final primaryColor = PdfColor.fromHex('#FF6B00');
    final darkColor = PdfColor.fromHex('#111827');
    final grayColor = PdfColor.fromHex('#6B7280');
    final lightBg = PdfColor.fromHex('#F9FAFB');
    final tableHeaderBg = PdfColor.fromHex('#F3F4F6');
    final borderLine = PdfColor.fromHex('#E5E7EB');
    final greenColor = PdfColor.fromHex('#15803D');
    final redColor = PdfColor.fromHex('#DC2626');

    double totalDebts = 0.0;
    double totalPayments = 0.0;
    for (var t in transactions) {
      if (t.type == CustomerTransactionType.orderDebt) {
        totalDebts += t.amount;
      } else if (t.type == CustomerTransactionType.payment || t.type == CustomerTransactionType.deposit) {
        totalPayments += t.amount;
      }
    }

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
                children: [
                  pw.Row(
                    children: [
                      pw.Image(pw.MemoryImage(logoBytes), width: 36, height: 36),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'MYNIX CONTROL',
                        style: pw.TextStyle(color: darkColor, fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('АКТ СВЕРКИ И ВЫПИСКА ГОСТЯ',
                          style: pw.TextStyle(color: primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Дата: $nowStr', style: pw.TextStyle(color: grayColor, fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: borderLine, thickness: 1),
              pw.SizedBox(height: 12),

              // Customer Info Block
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: borderLine),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Гость / Клиент:', style: pw.TextStyle(color: grayColor, fontSize: 9)),
                        pw.Text(customer.name, style: pw.TextStyle(color: darkColor, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        if (customer.phone != null)
                          pw.Text('Тел: ${customer.phone}', style: pw.TextStyle(color: grayColor, fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Текущий баланс:', style: pw.TextStyle(color: grayColor, fontSize: 9)),
                        pw.Text(
                          customer.balance < 0
                              ? 'Долг: ${customer.balance.abs().toStringAsFixed(2)} $currency'
                              : customer.balance > 0
                                  ? 'Депозит: ${customer.balance.toStringAsFixed(2)} $currency'
                                  : '0.00 $currency (В расчете)',
                          style: pw.TextStyle(
                            color: customer.balance < 0 ? redColor : (customer.balance > 0 ? greenColor : darkColor),
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Transactions Table
              pw.Text('История операций:', style: pw.TextStyle(color: darkColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: borderLine, width: 0.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: tableHeaderBg),
                    children: [
                      _th('Дата'),
                      _th('Тип операции'),
                      _th('Способ'),
                      _th('Комментарий'),
                      _th('Сумма ($currency)', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...transactions.map((t) {
                    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(t.date);
                    final isDebit = t.type == CustomerTransactionType.orderDebt;
                    return pw.TableRow(
                      children: [
                        _td(dateStr),
                        _td(t.type.label),
                        _td(t.paymentMethod == 'transfer' ? 'Перевод' : (t.paymentMethod == 'cash' ? 'Наличные' : t.paymentMethod)),
                        _td(t.comment ?? '—'),
                        _td(
                          '${isDebit ? '-' : '+'} ${t.amount.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          color: isDebit ? redColor : greenColor,
                          isBold: true,
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
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: borderLine),
                    ),
                    child: pw.Column(
                      children: [
                        _summaryRow('Покупок в долг:', '${totalDebts.toStringAsFixed(2)} $currency'),
                        pw.SizedBox(height: 4),
                        _summaryRow('Оплат и депозитов:', '${totalPayments.toStringAsFixed(2)} $currency'),
                        pw.Divider(color: borderLine, height: 8),
                        _summaryRow(
                          'Итоговое сальдо:',
                          '${customer.balance.toStringAsFixed(2)} $currency',
                          isBold: true,
                        ),
                      ],
                    ),
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

  static pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? color, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, color: color ?? PdfColors.grey900, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey900, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  static Future<void> downloadStatement(Customer customer, List<CustomerTransaction> transactions, String currency) async {
    final pdfBytes = await generatePdfBytes(customer, transactions, currency);
    final filename = 'Statement_${customer.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    export_helper.downloadBinaryFile(filename, pdfBytes, 'application/pdf');
  }
}
