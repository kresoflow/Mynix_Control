// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'document_pdf_components.dart';

// ==============================================================================
// 2. ТАБЛИЦА ПОЗИЦИЙ ДЛЯ PDF
// ==============================================================================
/// [ИНВАРИАНТ] Рендеринг таблицы номенклатуры документа в формате PDF.
class DocumentPdfTable {
  static String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  static pw.Widget build({
    required InventoryDocument doc,
    required String currency,
    required bool isReceipt,
    required bool isWriteOff,
    required bool isInventory,
    required pw.Font fontBold,
    required pw.Font fontReg,
  }) {
    final items = doc.items ?? [];

    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(
          color: DocumentPdfComponents.border,
          width: 0.5,
        ),
        bottom: pw.BorderSide(
          color: DocumentPdfComponents.border,
          width: 0.5,
        ),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(26),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: DocumentPdfComponents.bg,
          ),
          children: [
            DocumentPdfComponents.cell(
                '№', fontBold, 9, DocumentPdfComponents.gray,),
            DocumentPdfComponents.cell(
                'Наименование', fontBold, 9, DocumentPdfComponents.gray,),
            DocumentPdfComponents.cell(
              isInventory ? 'Учет' : 'Кол-во',
              fontBold,
              9,
              DocumentPdfComponents.gray,
              align: pw.TextAlign.right,
            ),
            DocumentPdfComponents.cell(
              isInventory
                  ? 'Факт'
                  : (isWriteOff ? 'Себест.' : 'Цена ($currency)'),
              fontBold,
              9,
              DocumentPdfComponents.gray,
              align: pw.TextAlign.right,
            ),
            DocumentPdfComponents.cell(
              isInventory ? 'Отклонение' : 'Сумма ($currency)',
              fontBold,
              9,
              DocumentPdfComponents.gray,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final it = e.value;
          final name = it.ingredientName ??
              it.retailProductName ??
              'Позиция ${e.key + 1}';
          if (isInventory) {
            final exp = it.expectedQuantity ?? it.quantity;
            final diff = it.quantity - exp;
            return pw.TableRow(
              children: [
                DocumentPdfComponents.cell(
                    '${e.key + 1}', fontReg, 9, DocumentPdfComponents.gray,),
                DocumentPdfComponents.cell(
                    name, fontBold, 10, DocumentPdfComponents.dark,),
                DocumentPdfComponents.cell(
                    _fmt(exp), fontReg, 10, DocumentPdfComponents.dark,
                    align: pw.TextAlign.right,),
                DocumentPdfComponents.cell(
                    _fmt(it.quantity), fontBold, 10, DocumentPdfComponents.dark,
                    align: pw.TextAlign.right,),
                DocumentPdfComponents.cell(
                  diff >= 0 ? '+${_fmt(diff)}' : _fmt(diff),
                  fontBold,
                  10,
                  diff < 0 ? PdfColors.red : PdfColors.green,
                  align: pw.TextAlign.right,
                ),
              ],
            );
          }
          return pw.TableRow(
            children: [
              DocumentPdfComponents.cell(
                  '${e.key + 1}', fontReg, 9, DocumentPdfComponents.gray,),
              DocumentPdfComponents.cell(
                  name, fontBold, 10, DocumentPdfComponents.dark,),
              DocumentPdfComponents.cell(
                  _fmt(it.quantity), fontReg, 10, DocumentPdfComponents.dark,
                  align: pw.TextAlign.right,),
              DocumentPdfComponents.cell(it.pricePerUnit.toStringAsFixed(2),
                  fontReg, 10, DocumentPdfComponents.dark,
                  align: pw.TextAlign.right,),
              DocumentPdfComponents.cell(
                '${it.totalPrice.toStringAsFixed(2)} $currency',
                fontBold,
                10,
                DocumentPdfComponents.dark,
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }
}
