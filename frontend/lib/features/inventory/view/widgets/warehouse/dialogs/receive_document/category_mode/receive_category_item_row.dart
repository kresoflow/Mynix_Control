// ==============================================================================
// МОДУЛЬ: Склад / Строка товара в категории прихода
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'receive_category_sync_adapter.dart';

/// Строка номенклатурной позиции внутри аккордеона категории склада.
class ReceiveCategoryItemRow extends StatefulWidget {
  final Ingredient item;
  final bool showRetailColumn;
  final String currency;
  final ReceiveCategorySyncAdapter adapter;

  const ReceiveCategoryItemRow({
    super.key,
    required this.item,
    required this.showRetailColumn,
    required this.currency,
    required this.adapter,
  });

  @override
  State<ReceiveCategoryItemRow> createState() => _ReceiveCategoryItemRowState();
}

class _ReceiveCategoryItemRowState extends State<ReceiveCategoryItemRow> {
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  late final TextEditingController _sellPriceController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    final a = widget.adapter;
    final q = a.getQuantity(widget.item), p = a.getCostPrice(widget.item), s = a.getSellPrice(widget.item);
    _qtyController = TextEditingController(text: q > 0 ? _formatNum(q) : '');
    _priceController = TextEditingController(text: p > 0 ? _formatNum(p) : '');
    _sellPriceController = TextEditingController(text: s > 0 ? _formatNum(s) : '');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  String _formatNum(double val) => val == val.roundToDouble() ? val.toInt().toString() : val.toString();
  double get _currentQty => double.tryParse(_qtyController.text) ?? 0.0;
  double get _currentPrice => double.tryParse(_priceController.text) ?? 0.0;

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required bool isDark,
    TextAlign textAlign = TextAlign.right,
    double width = 90,
  }) {
    return SizedBox(
      width: width,
      height: 34,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: textAlign,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
        decoration: buildBulkInputDecoration(context, hint, isHintOnly: true, contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowTotal = _currentQty * _currentPrice;
    final isDeficit = widget.item.isLowStock || widget.item.currentStock <= widget.item.minStockAlert;
    final hasReceipt = _currentQty > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: hasReceipt
              ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.04)
              : (_isHovered ? (isDark ? AppColors.darkSurface : AppColors.lightSurface) : Colors.transparent),
          border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            // 1. Иконка статуса и название позиции
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (hasReceipt)
                        const Padding(padding: EdgeInsets.only(right: 6), child: Icon(PhosphorIconsRegular.checkCircle, size: 14, color: AppColors.success)),
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: hasReceipt ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _buildAttributesRow(isDark),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 2. Текущий остаток на складе
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_formatNum(widget.item.currentStock)} ${UnitFormatter.format(widget.item.unit)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDeficit ? AppColors.danger : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                  Text(
                    isDeficit ? 'дефицит' : 'на складе',
                    style: TextStyle(fontSize: 10, fontWeight: isDeficit ? FontWeight.w600 : FontWeight.normal, color: isDeficit ? AppColors.danger : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Поле ввода «Приход» (Количество)
            _buildField(
              controller: _qtyController,
              hint: '0',
              textAlign: TextAlign.center,
              width: 80,
              isDark: isDark,
              onChanged: (val) {
                widget.adapter.updateQuantity(widget.item, double.tryParse(val) ?? 0.0);
                setState(() {});
              },
            ),
            const SizedBox(width: 8),

            // 4. Поле «Закупка»
            _buildField(
              controller: _priceController,
              hint: '0.00',
              width: 90,
              isDark: isDark,
              onChanged: (val) {
                widget.adapter.updateCostPrice(widget.item, double.tryParse(val) ?? 0.0);
                setState(() {});
              },
            ),

            // 5. Поле «Продажа» (только если в категории есть витрина)
            if (widget.showRetailColumn) ...[
              const SizedBox(width: 8),
              if (widget.item.isRetail)
                _buildField(
                  controller: _sellPriceController,
                  hint: '0.00',
                  width: 90,
                  isDark: isDark,
                  onChanged: (val) {
                    widget.adapter.updateSellPrice(widget.item, double.tryParse(val) ?? 0.0);
                    setState(() {});
                  },
                )
              else
                SizedBox(width: 90, child: Center(child: Text('—', style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, fontSize: 12)))),
            ],
            const SizedBox(width: 8),

            // 6. Сумма позиции
            SizedBox(
              width: 90,
              child: Text(
                rowTotal > 0 ? rowTotal.toCurrency(context) : '—',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: hasReceipt ? FontWeight.bold : FontWeight.w500,
                  color: hasReceipt ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributesRow(bool isDark) {
    final flavor = widget.item.attributes?['flavor']?.toString();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Text(UnitFormatter.format(widget.item.unit), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        ),
        if (flavor != null && flavor.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(flavor, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        ],
      ],
    );
  }
}
