import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add/bulk_add_category_selector.dart';

class ReceiveDocumentMetaRow extends StatelessWidget {
  final List<Supplier> suppliers;
  final int? selectedSupplierId;
  final ValueChanged<int?> onSupplierChanged;
  final VoidCallback onAddSupplier;
  final TextEditingController invoiceController;
  final TextEditingController reasonController;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final int? selectedParentId;
  final int? selectedChildId;
  final ValueChanged<int?> onParentChanged;
  final ValueChanged<int?> onChildChanged;

  const ReceiveDocumentMetaRow({
    super.key,
    required this.suppliers,
    required this.selectedSupplierId,
    required this.onSupplierChanged,
    required this.onAddSupplier,
    required this.invoiceController,
    required this.reasonController,
    required this.tabIndex,
    required this.onTabChanged,
    required this.selectedParentId,
    required this.selectedChildId,
    required this.onParentChanged,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Поставщик (необязательно)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(PhosphorIconsRegular.buildings),
                        ),
                        initialValue: selectedSupplierId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Без поставщика'),
                          ),
                          ...suppliers.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            );
                          }),
                        ],
                        onChanged: onSupplierChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Добавить поставщика',
                      child: Container(
                        height: 56, // Match the height of TextField
                        width: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          icon: const Icon(PhosphorIconsRegular.plus),
                          onPressed: onAddSupplier,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: invoiceController,
                  decoration: const InputDecoration(
                    labelText: 'Номер накладной',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(PhosphorIconsRegular.hash),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Комментарий',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(PhosphorIconsRegular.textAa),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // SMART CREATION TABS & CATEGORIES
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.magicWand, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Умное создание', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Новые названия будут автоматически созданы в указанной категории.', style: TextStyle(color: Colors.blue, fontSize: 13))),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('Витрина')),
                        ButtonSegment(value: 2, label: Text('Сырье')),
                      ],
                      selected: {tabIndex},
                      onSelectionChanged: (val) => onTabChanged(val.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BulkAddCategorySelector(
                  tabIndex: tabIndex,
                  selectedParentId: selectedParentId,
                  selectedChildId: selectedChildId,
                  onParentChanged: onParentChanged,
                  onChildChanged: onChildChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
