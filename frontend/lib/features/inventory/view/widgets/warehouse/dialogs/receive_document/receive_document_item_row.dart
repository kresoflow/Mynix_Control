import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'receipt_row_data.dart';
import 'receive_document_autocomplete_view.dart';
import 'receive_document_number_cell.dart';
import 'receive_document_retail_fields.dart';
import 'receive_document_row_callbacks.dart';
import 'receive_document_unit_cell.dart';

class ReceiveDocumentItemRow extends StatelessWidget {
  final List<ReceiptRowData> items;
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
    required this.items,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // 1. Name & Autocomplete
          Expanded(
            flex: isRetail ? 3 : 5,
            child: SizedBox(
              height: 40,
              child: Focus(
                onKeyEvent: (_, event) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
                  event: event,
                  items: items,
                  index: index,
                  targetNode: (r) => r.nameFocusNode,
                ),
                child: RawAutocomplete<Ingredient>(
                  textEditingController: item.nameController,
                  focusNode: item.nameFocusNode,
                  displayStringForOption: (option) => option.name,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Ingredient>.empty();
                    }
                    return availableIngredients.where((option) {
                      if (option.isArchived) return false;
                      final matchesText = option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      if (!matchesText) return false;
                      final isOptionRetail = option.attributes?['is_retail'] == true;
                      return isRetail ? isOptionRetail : !isOptionRetail;
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
                      decoration: buildBulkInputDecoration(context, 'Поиск номенклатуры...').copyWith(
                        suffixIcon: item.ingredient != null
                            ? const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.success, size: 16)
                            : Icon(PhosphorIconsRegular.magnifyingGlass, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 16),
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
          ),

          if (isRetail)
            ReceiveDocumentRetailFields(
              item: item,
              onFlavorSubmitted: onFlavorSubmitted,
              onVolumeSubmitted: onVolumeSubmitted,
            ),
          const SizedBox(width: 8),

          ReceiveDocumentUnitCell(
            selectedUnit: item.selectedUnit,
            onUnitChanged: onUnitChanged,
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          ReceiveDocumentNumberCell(
            width: isRetail ? 70 : 80,
            controller: item.qtyController,
            focusNode: item.qtyFocusNode,
            hint: '0',
            isDark: isDark,
            onChanged: onQtyChanged,
            onSubmitted: onQtySubmitted,
            onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
              event: ev, items: items, index: index, targetNode: (r) => r.qtyFocusNode,
            ),
          ),
          const SizedBox(width: 8),

          ReceiveDocumentNumberCell(
            width: isRetail ? 60 : 80,
            controller: item.minStockAlertController,
            focusNode: item.minStockAlertFocusNode,
            hint: '0',
            isDark: isDark,
            onChanged: onMinStockAlertChanged,
            onSubmitted: onMinStockAlertSubmitted,
            onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
              event: ev, items: items, index: index, targetNode: (r) => r.minStockAlertFocusNode,
            ),
          ),
          const SizedBox(width: 8),

          ReceiveDocumentNumberCell(
            width: isRetail ? 80 : 100,
            controller: item.priceController,
            focusNode: item.priceFocusNode,
            hint: '0.00',
            isDark: isDark,
            onChanged: onPriceChanged,
            onSubmitted: onPriceSubmitted,
            onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
              event: ev, items: items, index: index, targetNode: (r) => r.priceFocusNode,
            ),
          ),

          if (isRetail) ...[
            const SizedBox(width: 8),
            ReceiveDocumentNumberCell(
              width: 80,
              controller: item.sellPriceController,
              focusNode: item.sellPriceFocusNode,
              hint: '0.00',
              isDark: isDark,
              onChanged: onSellPriceChanged,
              onSubmitted: onSellPriceSubmitted,
              onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
                event: ev, items: items, index: index, targetNode: (r) => r.sellPriceFocusNode,
              ),
            ),
          ],
          const SizedBox(width: 8),

          SizedBox(
            width: isRetail ? 80 : 100,
            child: ValueListenableBuilder<double>(
              valueListenable: item.rowTotalNotifier,
              builder: (_, rowSum, __) => Text(
                rowSum.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
              onPressed: onRemove,
              tooltip: 'Удалить строку',
            ),
          ),
        ],
      ),
    );
  }
}
