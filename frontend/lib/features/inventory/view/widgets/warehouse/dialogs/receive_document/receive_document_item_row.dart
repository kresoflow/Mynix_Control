import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
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
    final isRetail = tabIndex == 1;
    final sum = item.quantity * item.price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // 1. Поиск / Название
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
                        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, i) {
                            final option = options.elementAt(i);
                            final optIsRetail = option.attributes?['is_retail'] == true;
                            return ListTile(
                              dense: true,
                              title: Text(option.name, style: AppTextStyles.bodyMedium),
                              subtitle: Text(optIsRetail ? 'Витрина' : 'Сырье', style: AppTextStyles.caption),
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

          // 2. Вкус (только витрина)
          if (isRetail) ...[
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: item.ingredient != null 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? const Color(0xFF10141D) : AppColors.lightCard,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.ingredient!.attributes?['Вкус'] ?? '—',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      )
                    : TextFormField(
                        controller: item.flavorController,
                        focusNode: item.flavorFocusNode,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        decoration: buildBulkInputDecoration(context, 'Вкус'),
                        onFieldSubmitted: (_) => onFlavorSubmitted(),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            // 3. Объем (только витрина)
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: item.ingredient != null 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? const Color(0xFF10141D) : AppColors.lightCard,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.ingredient!.attributes?['Объем'] ?? '—',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      )
                    : TextFormField(
                        controller: item.volumeController,
                        focusNode: item.volumeFocusNode,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        decoration: buildBulkInputDecoration(context, 'Объем'),
                        onFieldSubmitted: (_) => onVolumeSubmitted(),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 4. Ед. изм.
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                value: item.selectedUnit,
                isExpanded: true,
                decoration: buildBulkInputDecoration(context, 'Ед.'),
                items: ['шт', 'л', 'мл', 'кг', 'г', 'порц'].map((u) {
                  return DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: onUnitChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. Кол-во
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: TextFormField(
                controller: item.qtyController,
                focusNode: item.qtyFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: buildBulkInputDecoration(context, 'Кол-во'),
                onChanged: onQtyChanged,
                onFieldSubmitted: (_) => onQtySubmitted(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Алерт
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: TextFormField(
                controller: item.minStockAlertController,
                focusNode: item.minStockAlertFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: buildBulkInputDecoration(context, 'Алерт'),
                onChanged: onMinStockAlertChanged,
                onFieldSubmitted: (_) => onMinStockAlertSubmitted(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 7. Закупка
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: TextFormField(
                controller: item.priceController,
                focusNode: item.priceFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                decoration: buildBulkInputDecoration(context, 'Закупка'),
                onChanged: onPriceChanged,
                onFieldSubmitted: (_) => isRetail ? onPriceSubmitted() : onSellPriceSubmitted(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 8. Продажа (только витрина)
          if (isRetail) ...[
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 40,
                child: TextFormField(
                  controller: item.sellPriceController,
                  focusNode: item.sellPriceFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                  decoration: buildBulkInputDecoration(context, 'Продажа'),
                  onChanged: onSellPriceChanged,
                  onFieldSubmitted: (_) => onSellPriceSubmitted(),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 9. Сумма
          Expanded(
            flex: 1,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark ? const Color(0xFF10141D) : AppColors.lightCard,
              ),
              alignment: Alignment.centerRight,
              child: Text(
                sum.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? AppColors.info : AppColors.brandPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 10. Удалить
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash, size: 18),
            color: AppColors.danger.withValues(alpha: 0.8),
            onPressed: onRemove,
            tooltip: 'Удалить строку',
          ),
        ],
      ),
    );
  }
}
