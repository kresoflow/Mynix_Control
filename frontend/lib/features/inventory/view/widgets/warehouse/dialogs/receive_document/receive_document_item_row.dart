import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_data.dart';

class ReceiveDocumentItemRow extends StatelessWidget {
  final ReceiptRowData item;
  final int index;
  final bool isLast;
  final List<Ingredient> availableIngredients;
  final int tabIndex;
  
  final ValueChanged<Ingredient> onIngredientSelected;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNameSubmitted;
  final VoidCallback onFlavorSubmitted;
  final VoidCallback onVolumeSubmitted;
  final VoidCallback onQtySubmitted;
  final VoidCallback onPriceSubmitted;
  final ValueChanged<String?> onUnitChanged;
  final ValueChanged<String> onQtyChanged;
  final ValueChanged<String> onPriceChanged;
  final VoidCallback onRemove;

  const ReceiveDocumentItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.isLast,
    required this.availableIngredients,
    required this.tabIndex,
    required this.onIngredientSelected,
    required this.onNameChanged,
    required this.onNameSubmitted,
    required this.onFlavorSubmitted,
    required this.onVolumeSubmitted,
    required this.onQtySubmitted,
    required this.onPriceSubmitted,
    required this.onUnitChanged,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sum = item.quantity * item.price;

    return Row(
      children: [
        // Ingredient Autocomplete
        Expanded(
          flex: 2,
          child: RawAutocomplete<Ingredient>(
            textEditingController: item.nameController,
            focusNode: item.nameFocusNode,
            displayStringForOption: (option) => option.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Ingredient>.empty();
              }
              return availableIngredients.where((option) {
                return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: onIngredientSelected,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Поиск или новое название...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: item.ingredient != null
                      ? const Icon(PhosphorIconsRegular.checkCircle, color: Colors.green)
                      : const Icon(PhosphorIconsRegular.magicWand, color: Colors.blue),
                ),
                onChanged: onNameChanged,
                onFieldSubmitted: (_) => onNameSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int i) {
                        final option = options.elementAt(i);
                        final isRetail = option.attributes?['is_retail'] == true;
                        return ListTile(
                          title: Text(option.name),
                          subtitle: Text(isRetail ? "Витрина" : "Сырье", style: const TextStyle(fontSize: 12)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),

        // Flavor
        Expanded(
          child: item.ingredient != null 
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  child: Text(item.ingredient!.attributes?['Вкус'] ?? '-'),
                )
              : TextFormField(
                  controller: item.flavorController,
                  focusNode: item.flavorFocusNode,
                  enabled: tabIndex == 1,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(), 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: tabIndex == 2,
                    fillColor: tabIndex == 2 ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3) : null,
                  ),
                  onFieldSubmitted: (_) => onFlavorSubmitted(),
                ),
        ),
        const SizedBox(width: 16),

        // Volume
        Expanded(
          child: item.ingredient != null 
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  child: Text(item.ingredient!.attributes?['Объем'] ?? '-'),
                )
              : TextFormField(
                  controller: item.volumeController,
                  focusNode: item.volumeFocusNode,
                  enabled: tabIndex == 1,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(), 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    filled: tabIndex == 2,
                    fillColor: tabIndex == 2 ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3) : null,
                  ),
                  onFieldSubmitted: (_) => onVolumeSubmitted(),
                ),
        ),
        const SizedBox(width: 16),
        
        // Unit
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: item.selectedUnit,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            items: ['шт', 'л', 'мл', 'кг', 'г', 'порц'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: onUnitChanged,
          ),
        ),
        const SizedBox(width: 16),
        
        // Quantity
        Expanded(
          child: TextFormField(
            controller: item.qtyController,
            focusNode: item.qtyFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            onChanged: onQtyChanged,
            onFieldSubmitted: (_) => onQtySubmitted(),
          ),
        ),
        const SizedBox(width: 16),
        
        // Price
        Expanded(
          child: TextFormField(
            controller: item.priceController,
            focusNode: item.priceFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            onChanged: onPriceChanged,
            onFieldSubmitted: (_) => onPriceSubmitted(),
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
          onPressed: onRemove,
        ),
      ],
    );
  }
}
