import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:retail_os_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/document_event.dart';
import 'package:retail_os_frontend/features/inventory/bloc/document_state.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';
import 'package:retail_os_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:retail_os_frontend/features/inventory/models/supplier.dart';

class ReceiveDocumentDialog extends StatefulWidget {
  const ReceiveDocumentDialog({super.key});

  @override
  State<ReceiveDocumentDialog> createState() => _ReceiveDocumentDialogState();
}

class _ReceiveDocumentDialogState extends State<ReceiveDocumentDialog> {
  final _invoiceNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  int? _selectedSupplierId;
  
  List<Map<String, dynamic>> _items = [];
  List<Ingredient> _availableIngredients = [];
  bool _isLoadingIngredients = true;

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(LoadSuppliers());
    _loadIngredients();
  }
  
  Future<void> _loadIngredients() async {
    try {
      final repo = context.read<InventoryRepository>();
      final ingredients = await repo.getIngredients();
      final retail = await repo.getRetailProducts();
      setState(() {
        _availableIngredients = [...ingredients, ...retail];
        _isLoadingIngredients = false;
      });
    } catch (e) {
      setState(() => _isLoadingIngredients = false);
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'ingredient': null,
        'quantity': 1.0,
        'price': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _save({required bool complete}) {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите поставщика')),
      );
      return;
    }
    
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одну позицию')),
      );
      return;
    }

    final docItems = _items.map((item) {
      final Ingredient ing = item['ingredient'];
      final bool isRetail = ing.attributes?['is_retail'] == true;
      final qty = item['quantity'] as double;
      final price = item['price'] as double;
      
      return {
        'ingredient_id': !isRetail ? ing.id : null,
        'retail_product_id': isRetail ? ing.id : null,
        'quantity': qty,
        'price_per_unit': price,
        'total_price': qty * price,
      };
    }).toList();

    final data = {
      'type': 'receipt',
      'supplier_id': _selectedSupplierId,
      'invoice_number': _invoiceNumberController.text,
      'reason': _reasonController.text,
      'items': docItems,
    };

    // Note: To support "complete immediately", we could modify the API to accept status='completed'
    // or just call complete endpoint after creation. For MVP we just create.
    context.read<DocumentBloc>().add(CreateDocument(data));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.95;
    final height = MediaQuery.of(context).size.height * 0.95;
    
    double totalSum = 0;
    for (var item in _items) {
      totalSum += (item['quantity'] as double) * (item['price'] as double);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsRegular.truck, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text('Новая Приходная Накладная', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Meta Info Row
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<DocumentBloc, DocumentState>(
                      builder: (context, state) {
                        return DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Поставщик',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(PhosphorIconsRegular.buildings),
                          ),
                          value: _selectedSupplierId,
                          items: state.suppliers.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSupplierId = val),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _invoiceNumberController,
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
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Комментарий',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(PhosphorIconsRegular.textAa),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: Text('Товар / Сырье', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 16),
                  Expanded(child: Text('Ед. изм.', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 16),
                  Expanded(child: Text('Количество', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 16),
                  Expanded(child: Text('Цена (₸)', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 16),
                  Expanded(child: Text('Сумма (₸)', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 48), // Action
                ],
              ),
            ),

            // Table Body
            Expanded(
              child: _isLoadingIngredients
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final Ingredient? currentIng = item['ingredient'];
                        final sum = (item['quantity'] as double) * (item['price'] as double);

                        return Row(
                          children: [
                            // Ingredient Dropdown
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<Ingredient>(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                value: currentIng,
                                items: _availableIngredients.map((i) {
                                  final isRetail = i.attributes?['is_retail'] == true;
                                  return DropdownMenuItem(
                                    value: i,
                                    child: Text('${i.name} ${isRetail ? "(Ритейл)" : ""}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _items[index]['ingredient'] = val;
                                    if (val != null) {
                                      _items[index]['price'] = val.costPerUnit;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Unit (Readonly)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                ),
                                child: Text(currentIng?.unit ?? '-'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Quantity
                            Expanded(
                              child: TextFormField(
                                initialValue: item['quantity'].toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                                onChanged: (val) {
                                  final num = double.tryParse(val);
                                  if (num != null) {
                                    setState(() => _items[index]['quantity'] = num);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Price
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('price_${currentIng?.id ?? index}'), // force rebuild when ingredient changes
                                initialValue: item['price'].toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                                onChanged: (val) {
                                  final num = double.tryParse(val);
                                  if (num != null) {
                                    setState(() => _items[index]['price'] = num);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Total sum
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(sum.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Delete
                            IconButton(
                              icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            
            // Add row button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(PhosphorIconsRegular.plus),
                    label: const Text('Добавить строку (Enter)'),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Итого к оплате:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text('${totalSum.toStringAsFixed(2)} ₸', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _save(complete: false),
                    icon: const Icon(PhosphorIconsRegular.floppyDisk),
                    label: const Text('Сохранить черновик'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _save(complete: true),
                    icon: const Icon(PhosphorIconsRegular.checkCircle),
                    label: const Text('Провести документ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
