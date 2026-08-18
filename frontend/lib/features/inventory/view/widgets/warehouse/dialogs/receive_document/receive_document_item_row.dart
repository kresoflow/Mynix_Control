import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'receipt_row_data.dart';
import 'receive_document_autocomplete_view.dart';
import 'receive_document_retail_fields.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRetail = tabIndex == 1;
    final sum = item.quantity * item.price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // 1. Name & Autocomplete
          Expanded(
            flex: isRetail ? 3 : 5,
            child: SizedBox(
              height: 40,
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 13,
                    ),
                    decoration: buildBulkInputDecoration(context, 'Поиск или название...').copyWith(
                      suffixIcon: item.ingredient != null
                          ? const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.success, size: 16)
                          : const Icon(PhosphorIconsRegular.magicWand, color: AppColors.info, size: 16),
                    ),
                    onChanged: onNameChanged,
                    onFieldSubmitted: (_) => onNameSubmitted(),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return ReceiveDocumentAutocompleteOptionsView(
                    options: options,
                    onSelected: onSelected,
                  );
                },
              ),
            ),
          ),

          // 2. Retail specific fields
          if (isRetail)
            ReceiveDocumentRetailFields(
              item: item,
              onFlavorSubmitted: onFlavorSubmitted,
              onVolumeSubmitted: onVolumeSubmitted,
            ),

          const SizedBox(width: 6),

          // 3. Unit Selector
          SizedBox(
            width: 58,
            height: 40,
            child: DropdownButtonFormField<String>(
              initialValue: item.selectedUnit,
              decoration: buildBulkInputDecoration(context, ''),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 13,
              ),
              items: ['шт', 'л', 'мл', 'кг', 'г', 'порц'].map((u) {
                return DropdownMenuItem(value: u, child: Text(u));
              }).toList(),
              onChanged: onUnitChanged,
            ),
          ),

          const SizedBox(width: 6),

          // 4. Quantity
          SizedBox(
            width: 60,
            height: 40,
            child: TextFormField(
              controller: item.qtyController,
              focusNode: item.qtyFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 13,
              ),
              decoration: buildBulkInputDecoration(context, '0'),
              onChanged: onQtyChanged,
              onFieldSubmitted: (_) => onQtySubmitted(),
            ),
          ),

          const SizedBox(width: 6),

          // 5. Min Stock Alert
          SizedBox(
            width: 55,
            height: 40,
            child: TextFormField(
              controller: item.minStockAlertController,
              focusNode: item.minStockAlertFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 13,
              ),
              decoration: buildBulkInputDecoration(context, '0'),
              onChanged: onMinStockAlertChanged,
              onFieldSubmitted: (_) => onMinStockAlertSubmitted(),
            ),
          ),

          const SizedBox(width: 6),

          // 6. Cost Price
          SizedBox(
            width: 75,
            height: 40,
            child: TextFormField(
              controller: item.priceController,
              focusNode: item.priceFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 13,
              ),
              decoration: buildBulkInputDecoration(context, '0.00'),
              onChanged: onPriceChanged,
              onFieldSubmitted: (_) => onPriceSubmitted(),
            ),
          ),

          // 7. Sell Price (Retail only)
          if (isRetail) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 75,
              height: 40,
              child: TextFormField(
                controller: item.sellPriceController,
                focusNode: item.sellPriceFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 13,
                ),
                decoration: buildBulkInputDecoration(context, '0.00'),
                onChanged: onSellPriceChanged,
                onFieldSubmitted: (_) => onSellPriceSubmitted(),
              ),
            ),
          ],

          const SizedBox(width: 6),

          // 8. Total sum & Remove
          SizedBox(
            width: 90,
            child: Text(
              sum.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),

          const SizedBox(width: 6),

          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
            onPressed: onRemove,
            tooltip: 'Удалить строку',
          ),
        ],
      ),
    );
  }
}
