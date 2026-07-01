import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_model.dart';
import 'bulk_receipt_row_widget.dart';

class BulkReceiptView extends StatefulWidget {
  const BulkReceiptView({super.key});

  @override
  State<BulkReceiptView> createState() => _BulkReceiptViewState();
}

class _BulkReceiptViewState extends State<BulkReceiptView>
    with AutomaticKeepAliveClientMixin {
  final List<ReceiptRowModel> _rows = [];
  final TextEditingController _globalReasonController = TextEditingController(
    text: 'Приходная накладная',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    _globalReasonController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(ReceiptRowModel());
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_rows.isNotEmpty && _rows.last.searchFocus != null) {
        _rows.last.searchFocus!.requestFocus();
      }
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _saveAll() {
    final reason = _globalReasonController.text.trim().isEmpty
        ? 'Массовый приход'
        : _globalReasonController.text.trim();
    int addedCount = 0;

    for (var row in _rows) {
      if (row.ingredient == null) continue;
      final qty = double.tryParse(row.qtyController.text) ?? 0.0;
      if (qty <= 0) continue;

      final isRetail = row.ingredient!.attributes?['is_retail'] == true;
      context.read<IngredientBloc>().add(
        ReceiveStock(
          ingredientId: row.ingredient!.id,
          quantity: qty,
          reason: reason,
          isRetail: isRetail,
        ),
      );
      addedCount++;
    }

    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Массовый приход ($addedCount позиций) успешно сохранен!',
          ),
        ),
      );
      _clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Накладная пуста или заполнена неверно!')),
      );
    }
  }

  void _clearForm() {
    for (var row in _rows) {
      row.dispose();
    }
    setState(() {
      _globalReasonController.text = 'Приходная накладная';
      _rows.clear();
      _addRow();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(PhosphorIconsRegular.receipt, size: 32, color: Colors.grey),
                const SizedBox(width: 16),
                const Text(
                  'Приходная накладная',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                  tooltip: 'Очистить форму',
                  onPressed: _clearForm,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 400,
              child: TextField(
                controller: _globalReasonController,
                decoration: const InputDecoration(
                  labelText:
                      'Комментарий к накладной (поставщик, номер документа)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(PhosphorIconsRegular.notepad),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Header
            Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Товар / Сырье',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Кол-во',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Цена закупки',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: BlocBuilder<IngredientBloc, IngredientState>(
                builder: (context, state) {
                  List<Ingredient> ingredients = [];
                  if (state is IngredientLoaded) {
                    ingredients = state.ingredients;
                  }

                  return ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return BulkReceiptRowWidget(
                        row: row,
                        index: index,
                        isLast: index == _rows.length - 1,
                        ingredients: ingredients,
                        onRemove: () => _removeRow(index),
                        onAddRow: _addRow,
                        onFocusNextSearch: (nextIndex) {
                          if (nextIndex < _rows.length) {
                            _rows[nextIndex].searchFocus?.requestFocus();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(PhosphorIconsRegular.plus),
                  label: const Text('Добавить строку'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearForm,
                      child: const Text(
                        'Отмена',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _saveAll,
                      icon: const Icon(PhosphorIconsRegular.check),
                      label: const Text('Провести документ'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
