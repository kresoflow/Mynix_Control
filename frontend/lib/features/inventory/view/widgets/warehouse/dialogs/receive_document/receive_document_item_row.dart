import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_data.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';


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
  final VoidCallback onSellPriceSubmitted;
  final ValueChanged<String> onSellPriceChanged;
  final VoidCallback onMinStockAlertSubmitted;
  final ValueChanged<String> onMinStockAlertChanged;
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
    required this.onSellPriceSubmitted,
    required this.onSellPriceChanged,
    required this.onMinStockAlertSubmitted,
    required this.onMinStockAlertChanged,
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
                      ? Icon(PhosphorIconsRegular.checkCircle, color: AppColors.success)
                      : Icon(PhosphorIconsRegular.magicWand, color: AppColors.info),
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
        const SizedBox(width: 12),

        // Flavor
        Expanded(
          child: item.ingredient != null 
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                    fillColor: tabIndex == 2 ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : null,
                  ),
                  onFieldSubmitted: (_) => onFlavorSubmitted(),
                ),
        ),
        const SizedBox(width: 12),

        // Volume
        Expanded(
          child: item.ingredient != null 
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                    fillColor: tabIndex == 2 ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : null,
                  ),
                  onFieldSubmitted: (_) => onVolumeSubmitted(),
                ),
        ),
        const SizedBox(width: 12),
        
        // Unit
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: item.selectedUnit,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            items: ['шт', 'л', 'мл', 'кг', 'г', 'порц'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: onUnitChanged,
          ),
        ),
        const SizedBox(width: 12),
        
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
        const SizedBox(width: 12),
        
        // Alert (Min Stock)
        Expanded(
          child: TextFormField(
            controller: item.minStockAlertController,
            focusNode: item.minStockAlertFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            onChanged: onMinStockAlertChanged,
            onFieldSubmitted: (_) => onMinStockAlertSubmitted(),
          ),
        ),
        const SizedBox(width: 12),
        
        // Purchase Price
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
        const SizedBox(width: 12),

        // Selling Price
        Expanded(
          child: TextFormField(
            controller: item.sellPriceController,
            focusNode: item.sellPriceFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            onChanged: onSellPriceChanged,
            onFieldSubmitted: (_) => onSellPriceSubmitted(),
          ),
        ),
        const SizedBox(width: 12),

        // Total sum
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(sum.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.info)),
          ),
        ),
        const SizedBox(width: 48),

        // Delete
        IconButton(
          icon: Icon(PhosphorIconsRegular.trash, color: AppColors.danger),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
