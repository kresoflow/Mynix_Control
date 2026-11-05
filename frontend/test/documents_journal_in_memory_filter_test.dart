// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/warehouse/documents/documents_toolbar.dart';

// ==============================================================================
// 2. ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ IN-MEMORY ФИЛЬТРАЦИИ ЖУРНАЛА
// ==============================================================================
/// [ИНВАРИАНТ] Идентична предикату фильтрации из DocumentsJournalTab.
List<InventoryDocument> filterDocuments({
  required List<InventoryDocument> documents,
  required String selectedFilter,
  required String searchQuery,
}) {
  return documents.where((d) {
    if (selectedFilter != 'all' && d.type != selectedFilter) return false;
    if (searchQuery.isEmpty) return true;
    final q = searchQuery.toLowerCase().trim();
    return d.id.toString().contains(q) ||
        (d.supplierName != null && d.supplierName!.toLowerCase().contains(q)) ||
        (d.reason != null && d.reason!.toLowerCase().contains(q)) ||
        (d.invoiceNumber != null && d.invoiceNumber!.toLowerCase().contains(q));
  }).toList();
}

// ==============================================================================
// 3. ТЕСТЫ IN-MEMORY ФИЛЬТРАЦИИ И ТУЛБАРА ЖУРНАЛА ДОКУМЕНТОВ
// ==============================================================================
void main() {
  final doc1 = InventoryDocument(
    id: 101,
    type: 'receipt',
    status: 'completed',
    date: DateTime.parse('2026-10-30T10:00:00Z'),
    supplierName: 'ООО Ромашка',
    invoiceNumber: 'INV-001',
    reason: 'Приход молока',
    totalAmount: 1500.0,
  );

  final doc2 = InventoryDocument(
    id: 102,
    type: 'write_off',
    status: 'completed',
    date: DateTime.parse('2026-10-30T11:00:00Z'),
    reason: 'Порча продуктов',
    totalAmount: 320.0,
  );

  final doc3 = InventoryDocument(
    id: 103,
    type: 'inventory',
    status: 'completed',
    date: DateTime.parse('2026-10-30T12:00:00Z'),
    reason: 'Сплошной пересчет',
    totalAmount: 0.0,
  );

  final allDocs = [doc1, doc2, doc3];

  group('DocumentsJournal In-Memory Filtering Tests', () {
    testWidgets('1. DocumentsToolbar отображает чипы и переключает фильтр без сети', (tester) async {
      String currentFilter = 'all';
      String currentSearch = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DocumentsToolbar(
                  selectedFilter: currentFilter,
                  onFilterChanged: (val) => setState(() => currentFilter = val),
                  searchQuery: currentSearch,
                  onSearchChanged: (val) => setState(() => currentSearch = val),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Проверяем отображение всех чипов
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Приходы'), findsOneWidget);
      expect(find.text('Списания'), findsOneWidget);
      expect(find.text('Инвентаризации'), findsOneWidget);

      // Кликаем по «Приходы»
      await tester.tap(find.text('Приходы'));
      await tester.pumpAndSettle();
      expect(currentFilter, equals('receipt'));

      // Кликаем по «Списания»
      await tester.tap(find.text('Списания'));
      await tester.pumpAndSettle();
      expect(currentFilter, equals('write_off'));

      // Кликаем по «Инвентаризации»
      await tester.tap(find.text('Инвентаризации'));
      await tester.pumpAndSettle();
      expect(currentFilter, equals('inventory'));

      // Возврат во «Все»
      await tester.tap(find.text('Все'));
      await tester.pumpAndSettle();
      expect(currentFilter, equals('all'));
    });

    test('2. In-memory фильтрация по типу документа работает мгновенно', () {
      final receipts = filterDocuments(
        documents: allDocs,
        selectedFilter: 'receipt',
        searchQuery: '',
      );
      expect(receipts.length, equals(1));
      expect(receipts.first.id, equals(101));

      final writeOffs = filterDocuments(
        documents: allDocs,
        selectedFilter: 'write_off',
        searchQuery: '',
      );
      expect(writeOffs.length, equals(1));
      expect(writeOffs.first.id, equals(102));

      final inventories = filterDocuments(
        documents: allDocs,
        selectedFilter: 'inventory',
        searchQuery: '',
      );
      expect(inventories.length, equals(1));
      expect(inventories.first.id, equals(103));
    });

    test('3. In-memory фильтрация по строке поиска находит документы по поставщику, номеру и причине', () {
      // По номеру накладной
      final byInvoice = filterDocuments(
        documents: allDocs,
        selectedFilter: 'all',
        searchQuery: 'INV-001',
      );
      expect(byInvoice.length, equals(1));
      expect(byInvoice.first.id, equals(101));

      // По поставщику
      final bySupplier = filterDocuments(
        documents: allDocs,
        selectedFilter: 'all',
        searchQuery: 'ромашка',
      );
      expect(bySupplier.length, equals(1));
      expect(bySupplier.first.id, equals(101));

      // По причине списания
      final byReason = filterDocuments(
        documents: allDocs,
        selectedFilter: 'all',
        searchQuery: 'порча',
      );
      expect(byReason.length, equals(1));
      expect(byReason.first.id, equals(102));

      // По числовому ID
      final byId = filterDocuments(
        documents: allDocs,
        selectedFilter: 'all',
        searchQuery: '103',
      );
      expect(byId.length, equals(1));
      expect(byId.first.id, equals(103));
    });

    test('4. Комбинация типа и поиска фильтрует пересечение и сбрасывается', () {
      // Ищем "INV-001" в категории "Списания" -> 0 совпадений
      final mismatch = filterDocuments(
        documents: allDocs,
        selectedFilter: 'write_off',
        searchQuery: 'INV-001',
      );
      expect(mismatch, isEmpty);

      // Сброс фильтров (selectedFilter='all', searchQuery='') -> снова 3 документа
      final reset = filterDocuments(
        documents: allDocs,
        selectedFilter: 'all',
        searchQuery: '',
      );
      expect(reset.length, equals(3));
    });
  });
}
