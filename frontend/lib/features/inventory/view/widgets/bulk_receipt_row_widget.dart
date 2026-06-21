import 'package:flutter/material.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_model.dart';

class BulkReceiptRowWidget extends StatelessWidget {
  final ReceiptRowModel row;
  final int index;
  final bool isLast;
  final List<Ingredient> ingredients;
  final VoidCallback onRemove;
  final VoidCallback onAddRow;
  final Function(int) onFocusNextSearch;

  const BulkReceiptRowWidget({
    super.key,
    required this.row,
    required this.index,
    required this.isLast,
    required this.ingredients,
    required this.onRemove,
    required this.onAddRow,
    required this.onFocusNextSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Autocomplete<Ingredient>(
              displayStringForOption: (Ingredient option) => option.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Ingredient>.empty();
                }
                return ingredients.where((Ingredient option) {
                  return option.name.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (Ingredient selection) {
                row.ingredient = selection;
                if (row.costController.text.isEmpty) {
                  row.costController.text = selection.costPerUnit.toString();
                }
                row.qtyFocus.requestFocus();
              },
              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    row.searchFocus = fieldFocusNode;
                    if (row.ingredient != null &&
                        fieldTextEditingController.text.isEmpty) {
                      fieldTextEditingController.text = row.ingredient!.name;
                    }
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'Поиск товара...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                    );
                  },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextField(
              controller: row.qtyController,
              focusNode: row.qtyFocus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                row.costFocus.requestFocus();
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                suffixText: row.ingredient?.unit ?? '',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextField(
              controller: row.costController,
              focusNode: row.costFocus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (isLast) {
                  onAddRow();
                } else {
                  onFocusNextSearch(index + 1);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                suffixText: 'c',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            hoverColor: Colors.red.withValues(alpha: 0.1),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
