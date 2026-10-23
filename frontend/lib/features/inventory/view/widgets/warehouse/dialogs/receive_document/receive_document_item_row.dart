// ==============================================================================
// МОДУЛЬ: Склад / Строка товара приходной накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'receipt_row_data.dart';
import 'receive_document_autocomplete_view.dart';
import 'receive_document_number_cell.dart';
import 'receive_document_row_callbacks.dart';
import 'receive_document_unit_cell.dart';

/// Строка номенклатурной позиции в приходной накладной.
/// Оформлена в стиле массового добавления (Bulk Add) с выровненными колонками,
/// эффектом наведения мыши и числовыми полями без плавающих дублирующихся меток.
class ReceiveDocumentItemRow extends StatefulWidget {
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
  State<ReceiveDocumentItemRow> createState() => _ReceiveDocumentItemRowState();
}

class _ReceiveDocumentItemRowState extends State<ReceiveDocumentItemRow> {
  final ValueNotifier<bool> _isHovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isHovered.dispose();
    super.dispose();
  }

  Widget _buildDashCell(bool isDark, {int? flex, double? width}) {
    final text = Center(
      child: Text(
        '—',
        style: TextStyle(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return flex != null ? Expanded(flex: flex, child: SizedBox(height: 40, child: text)) : SizedBox(width: width, height: 40, child: text);
  }

  Widget _buildTextField(TextEditingController ctrl, FocusNode node, String hint, VoidCallback onSubmitted, int flex, bool isDark) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: 40,
        child: TextFormField(
          controller: ctrl,
          focusNode: node,
          style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText, fontSize: 13),
          decoration: buildBulkInputDecoration(context, hint, isHintOnly: true),
          onFieldSubmitted: (_) => onSubmitted(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showRetailColumns = widget.tabIndex == 0 || widget.tabIndex == 1;
    final isRawItem = widget.item.ingredient != null && !widget.item.ingredient!.isRetail;

    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isHovered,
        builder: (context, hovered, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: hovered
                  ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                  : AppColors.transparent,
              borderRadius: AppRadii.inputRadius,
              border: Border.all(
                color: hovered
                    ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    : AppColors.transparent,
              ),
            ),
            child: Row(
              children: [
                // 1. Порядковый номер
                SizedBox(
                  width: 32,
                  child: Text(
                    '${widget.index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Поиск и автокомплит номенклатуры
                ReceiveDocumentAutocompleteField(
                  item: widget.item,
                  index: widget.index,
                  items: widget.items,
                  availableIngredients: widget.availableIngredients,
                  tabIndex: widget.tabIndex,
                  isDark: isDark,
                  onIngredientSelected: widget.onIngredientSelected,
                  onNameChanged: widget.onNameChanged,
                  onNameSubmitted: widget.onNameSubmitted,
                ),

                // 3. Вкус и объем (витрина или прочерк для сырья во вкладке Все)
                if (showRetailColumns) ...[
                  const SizedBox(width: 8),
                  if (isRawItem)
                    _buildDashCell(isDark, flex: 2)
                  else
                    _buildTextField(widget.item.flavorController, widget.item.flavorFocusNode, 'Вкус (или пусто)', widget.onFlavorSubmitted, 2, isDark),
                  const SizedBox(width: 8),
                  if (isRawItem)
                    _buildDashCell(isDark, flex: 1)
                  else
                    _buildTextField(widget.item.volumeController, widget.item.volumeFocusNode, 'Объем', widget.onVolumeSubmitted, 1, isDark),
                ],
                const SizedBox(width: 8),

                // 4. Единица измерения
                ReceiveDocumentUnitCell(
                  selectedUnit: widget.item.selectedUnit,
                  onUnitChanged: widget.onUnitChanged,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),

                // 5. Количество
                ReceiveDocumentNumberCell(
                  width: 85,
                  controller: widget.item.qtyController,
                  focusNode: widget.item.qtyFocusNode,
                  hint: '0',
                  textAlign: TextAlign.center,
                  isDark: isDark,
                  onChanged: widget.onQtyChanged,
                  onSubmitted: widget.onQtySubmitted,
                  onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
                    event: ev, items: widget.items, index: widget.index, targetNode: (r) => r.qtyFocusNode,
                  ),
                ),
                const SizedBox(width: 8),

                // 6. Минимальный остаток (алерт)
                ReceiveDocumentNumberCell(
                  width: 80,
                  controller: widget.item.minStockAlertController,
                  focusNode: widget.item.minStockAlertFocusNode,
                  hint: '0',
                  textAlign: TextAlign.center,
                  isDark: isDark,
                  onChanged: widget.onMinStockAlertChanged,
                  onSubmitted: widget.onMinStockAlertSubmitted,
                  onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
                    event: ev, items: widget.items, index: widget.index, targetNode: (r) => r.minStockAlertFocusNode,
                  ),
                ),
                const SizedBox(width: 8),

                // 7. Закупочная цена
                ReceiveDocumentNumberCell(
                  width: 105,
                  controller: widget.item.priceController,
                  focusNode: widget.item.priceFocusNode,
                  hint: '0.00',
                  textAlign: TextAlign.right,
                  isDark: isDark,
                  onChanged: widget.onPriceChanged,
                  onSubmitted: widget.onPriceSubmitted,
                  onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
                    event: ev, items: widget.items, index: widget.index, targetNode: (r) => r.priceFocusNode,
                  ),
                ),

                // 8. Цена продажи (витрина или прочерк для сырья во вкладке Все)
                if (showRetailColumns) ...[
                  const SizedBox(width: 8),
                  if (isRawItem)
                    _buildDashCell(isDark, width: 105)
                  else
                    ReceiveDocumentNumberCell(
                      width: 105,
                      controller: widget.item.sellPriceController,
                      focusNode: widget.item.sellPriceFocusNode,
                      hint: '0.00',
                      textAlign: TextAlign.right,
                      isDark: isDark,
                      onChanged: widget.onSellPriceChanged,
                      onSubmitted: widget.onSellPriceSubmitted,
                      onKeyEvent: (_, ev) => ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
                        event: ev, items: widget.items, index: widget.index, targetNode: (r) => r.sellPriceFocusNode,
                      ),
                    ),
                ],
                const SizedBox(width: 8),

                // 9. Сумма по строке
                SizedBox(
                  width: 95,
                  child: ValueListenableBuilder<double>(
                    valueListenable: widget.item.rowTotalNotifier,
                    builder: (_, rowSum, __) => Text(
                      rowSum.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 10. Кнопка удаления
                SizedBox(
                  width: 36,
                  child: IconButton(
                    icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
                    onPressed: widget.onRemove,
                    tooltip: 'Удалить строку',
                    visualDensity: VisualDensity.compact,
                    splashRadius: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
