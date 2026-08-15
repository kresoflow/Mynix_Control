import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'receipt_row_data.dart';
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
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final sum = item.quantity * item.price;

    InputDecoration cellDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        filled: true,
        fillColor: bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Ingredient Autocomplete
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 38,
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
                    decoration: cellDecoration('Поиск или название...').copyWith(
                      suffixIcon: item.ingredient != null
                          ? Icon(PhosphorIconsRegular.checkCircle, color: AppColors.success, size: 16)
                          : Icon(PhosphorIconsRegular.magicWand, color: AppColors.info, size: 16),
                    ),
                    onChanged: onNameChanged,
                    onFieldSubmitted: (_) => onNameSubmitted(),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, i) {
                            final option = options.elementAt(i);
                            final isRetail = option.attributes?['is_retail'] == true;
                            return ListTile(
                              dense: true,
                              title: Text(option.name, style: AppTextStyles.bodyMedium),
                              subtitle: Text(isRetail ? 'Витрина' : 'Сырье', style: AppTextStyles.caption),
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
          ),
          const SizedBox(width: 8),

          // Flavor
          Expanded(
            child: SizedBox(
              height: 38,
              child: item.ingredient != null 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                        color: bg,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.ingredient!.attributes?['Вкус'] ?? '-',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    )
                  : TextFormField(
                      controller: item.flavorController,
                      focusNode: item.flavorFocusNode,
                      enabled: tabIndex == 1,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                      decoration: cellDecoration('Вкус'),
                      onFieldSubmitted: (_) => onFlavorSubmitted(),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Volume
          Expanded(
            child: SizedBox(
              height: 38,
              child: item.ingredient != null 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                        color: bg,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.ingredient!.attributes?['Объем'] ?? '-',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    )
                  : TextFormField(
                      controller: item.volumeController,
                      focusNode: item.volumeFocusNode,
                      enabled: tabIndex == 1,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                      decoration: cellDecoration('Объем'),
                      onFieldSubmitted: (_) => onVolumeSubmitted(),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Unit
          Expanded(
            child: SizedBox(
              height: 38,
              child: DropdownButtonFormField<String>(
                initialValue: item.selectedUnit,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 13,
                ),
                decoration: cellDecoration('Ед. изм.'),
                items: ['шт', 'л', 'мл', 'кг', 'г', 'порц'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: onUnitChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Quantity
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextFormField(
                controller: item.qtyController,
                focusNode: item.qtyFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: cellDecoration('1'),
                onChanged: onQtyChanged,
                onFieldSubmitted: (_) => onQtySubmitted(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Alert (Min Stock)
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextFormField(
                controller: item.minStockAlertController,
                focusNode: item.minStockAlertFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: cellDecoration('0'),
                onChanged: onMinStockAlertChanged,
                onFieldSubmitted: (_) => onMinStockAlertSubmitted(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Purchase Price
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextFormField(
                controller: item.priceController,
                focusNode: item.priceFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: cellDecoration('0.00'),
                onChanged: onPriceChanged,
                onFieldSubmitted: (_) => onPriceSubmitted(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Selling Price
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextFormField(
                controller: item.sellPriceController,
                focusNode: item.sellPriceFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: cellDecoration('0.00'),
                onChanged: onSellPriceChanged,
                onFieldSubmitted: (_) => onSellPriceSubmitted(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Total sum
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                sum.toStringAsFixed(2),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.info,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delete
          IconButton(
            icon: Icon(PhosphorIconsRegular.trash, color: AppColors.danger, size: 18),
            onPressed: onRemove,
            tooltip: 'Удалить строку',
          ),
        ],
      ),
    );
  }
}
