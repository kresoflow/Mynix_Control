// ==============================================================================
// 1. ИМПОРТЫ И ТЕСТОВЫЙ КОНТЕКСТ
// ==============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/services/document_export_service.dart';
import 'package:kreso_frontend/features/inventory/services/export/document_text_builder.dart';

void main() {
  group('DocumentTextBuilder & Export Tests', () {
    final testDate = DateTime(2026, 10, 5, 14, 30);

    // ============================================================================
    // 2. ТЕСТЫ АКТА СПИСАНИЯ
    // ============================================================================
    test('buildPlainText for write_off renders correct header and fields', () {
      final doc = InventoryDocument(
        id: 7,
        type: 'write_off',
        date: testDate,
        status: 'completed',
        reason: 'Порча продуктов',
        totalAmount: 450.0,
        items: [
          InventoryDocumentItem(
            id: 1,
            documentId: 7,
            ingredientId: 10,
            ingredientName: 'Томаты свежие',
            quantity: 3.0,
            pricePerUnit: 150.0,
            totalPrice: 450.0,
          ),
        ],
      );

      final text = DocumentTextBuilder.buildPlainText(doc, 'с');

      // Проверка наличия ключевых полей списания
      expect(text, contains('АКТ СПИСАНИЯ #7'));
      expect(text, contains('Причина: Порча продуктов'));
      expect(text, contains('Томаты свежие — 3 шт × 150.00 с = 450.00 с'));
      expect(text, contains('ИТОГО СПИСАНИЕ: 450.00 с'));

      // [ИНВАРИАНТ] Никаких атрибутов накладной в акте списания!
      expect(text, isNot(contains('ПРИХОДНАЯ НАКЛАДНАЯ')));
      expect(text, isNot(contains('Поставщик')));
      expect(text, isNot(contains('Оплата: В долг')));
      expect(text, isNot(contains('ИТОГО К ОПЛАТЕ')));
    });

    test('buildCsv for write_off generates valid CSV structure', () {
      final doc = InventoryDocument(
        id: 7,
        type: 'write_off',
        date: testDate,
        status: 'completed',
        reason: 'Истек срок годности',
        totalAmount: 200.0,
        items: [
          InventoryDocumentItem(
            id: 1,
            documentId: 7,
            ingredientId: 2,
            ingredientName: 'Молоко 3.2%',
            quantity: 2.0,
            pricePerUnit: 100.0,
            totalPrice: 200.0,
          ),
        ],
      );

      final csv = DocumentTextBuilder.buildCsv(doc, 'сом');
      expect(csv.startsWith('\uFEFF'), isTrue); // BOM для Excel
      expect(csv, contains('АКТ СПИСАНИЯ #7'));
      expect(csv, contains('Причина списания: Истек срок годности'));
      expect(
          csv,
          contains(
              '№;Наименование;Количество;Себестоимость (сом);Сумма списания (сом)',),);
      expect(csv, contains('ИТОГО СПИСАНИЕ:;200.00'));
    });

    // ============================================================================
    // 3. ТЕСТЫ АКТА ИНВЕНТАРИЗАЦИИ
    // ============================================================================
    test('buildPlainText for inventory renders audit differences', () {
      final doc = InventoryDocument(
        id: 12,
        type: 'inventory',
        date: testDate,
        status: 'completed',
        reason: 'Плановая ревизия',
        totalAmount: 0.0,
        items: [
          InventoryDocumentItem(
            id: 1,
            documentId: 12,
            ingredientId: 5,
            ingredientName: 'Сыр Моцарелла',
            quantity: 8.0,
            expectedQuantity: 10.0,
            pricePerUnit: 500.0,
            totalPrice: 4000.0,
          ),
        ],
      );

      final text = DocumentTextBuilder.buildPlainText(doc, 'с');

      expect(text, contains('АКТ ИНВЕНТАРИЗАЦИИ #12'));
      expect(text, contains('Тип: Плановая ревизия'));
      expect(text, contains('факт 8 (учет 10)'));
      expect(text, contains('откл: -2 (-1000.00 с)'));
      expect(text, contains('ИТОГОВОЕ РАСХОЖДЕНИЕ: -1000.00 с'));

      // Запрет атрибутов приходной накладной
      expect(text, isNot(contains('ПРИХОДНАЯ НАКЛАДНАЯ')));
      expect(text, isNot(contains('Поставщик')));
      expect(text, isNot(contains('ИТОГО К ОПЛАТЕ')));
    });

    // ============================================================================
    // 4. ТЕСТЫ ПРИХОДНОЙ НАКЛАДНОЙ
    // ============================================================================
    test('buildPlainText for receipt renders supplier and payment', () {
      final doc = InventoryDocument(
        id: 3,
        type: 'receipt',
        date: testDate,
        status: 'completed',
        supplierName: 'ОсОО «Агропром»',
        invoiceNumber: 'INV-2026-99',
        paymentStatus: 'paid',
        totalAmount: 1500.0,
        items: [
          InventoryDocumentItem(
            id: 1,
            documentId: 3,
            ingredientId: 1,
            ingredientName: 'Мука в/с',
            quantity: 30.0,
            pricePerUnit: 50.0,
            totalPrice: 1500.0,
          ),
        ],
      );

      final text = DocumentTextBuilder.buildPlainText(doc, 'с');

      expect(text, contains('ПРИХОДНАЯ НАКЛАДНАЯ #3'));
      expect(text, contains('Поставщик: ОсОО «Агропром»'));
      expect(text, contains('Инвойс: INV-2026-99'));
      expect(text, contains('Оплата: Оплачено'));
      expect(text, contains('ИТОГО К ОПЛАТЕ: 1500.00 с'));
    });

    // ============================================================================
    // 5. ТЕСТЫ ДИНАМИЧЕСКИХ ИМЕН ФАЙЛОВ
    // ============================================================================
    test('DocumentExportService builds contextual file names', () {
      final writeOffDoc = InventoryDocument(
        id: 7,
        type: 'write_off',
        date: testDate,
        status: 'completed',
        totalAmount: 100.0,
      );
      final invDoc = InventoryDocument(
        id: 15,
        type: 'inventory',
        date: testDate,
        status: 'completed',
        totalAmount: 0.0,
      );
      final receiptDoc = InventoryDocument(
        id: 42,
        type: 'receipt',
        date: testDate,
        status: 'completed',
        totalAmount: 500.0,
      );

      expect(DocumentExportService.buildFileName(writeOffDoc, 'txt'),
          'akt_spisaniya_7.txt',);
      expect(DocumentExportService.buildFileName(writeOffDoc, 'pdf'),
          'akt_spisaniya_7.pdf',);
      expect(DocumentExportService.buildFileName(writeOffDoc, 'csv'),
          'akt_spisaniya_7.csv',);

      expect(DocumentExportService.buildFileName(invDoc, 'txt'),
          'akt_inventarizacii_15.txt',);
      expect(DocumentExportService.buildFileName(invDoc, 'pdf'),
          'akt_inventarizacii_15.pdf',);

      expect(DocumentExportService.buildFileName(receiptDoc, 'txt'),
          'nakladnaya_42.txt',);
      expect(DocumentExportService.buildFileName(receiptDoc, 'pdf'),
          'nakladnaya_42.pdf',);
    });
  });
}
