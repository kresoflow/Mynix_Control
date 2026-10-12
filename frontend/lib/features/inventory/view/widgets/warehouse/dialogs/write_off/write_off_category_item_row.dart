// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'write_off_items_table.dart';

// ==============================================================================
// 2. СТРОКА ТОВАРА ВНУТРИ КАТЕГОРИИ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Строка номенклатуры в аккордеоне категории с полем ввода списания.
class WriteOffCategoryItemRow extends StatefulWidget {
  final Ingredient item;
  final WriteOffItemEntry? entry;
  final String currency;
  final void Function(Ingredient item, double qty) onQuantityChanged;
  final bool isLast;

  const WriteOffCategoryItemRow({
    super.key,
    required this.item,
    required this.entry,
    required this.currency,
    required this.onQuantityChanged,
    this.isLast = false,
  });

  @override
  State<WriteOffCategoryItemRow> createState() =>
      _WriteOffCategoryItemRowState();
}

class _WriteOffCategoryItemRowState extends State<WriteOffCategoryItemRow> {
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    final q = widget.entry?.quantity ?? 0.0;
    _qtyController = TextEditingController(
      text: q > 0
          ? (q == q.truncateToDouble() ? q.toInt().toString() : q.toString())
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant WriteOffCategoryItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.quantity != widget.entry?.quantity) {
      final q = widget.entry?.quantity ?? 0.0;
      final currentParsed =
          double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0.0;
      if (currentParsed != q) {
        _qtyController.text = q > 0
            ? (q == q.truncateToDouble() ? q.toInt().toString() : q.toString())
            : '';
      }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    final str = v.toStringAsFixed(3);
    final trimmed =
        str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = UnitFormatter.format(widget.item.unit);
    final currentQty = widget.entry?.quantity ?? 0.0;
    final isStockLow = widget.entry != null &&
        widget.item.currentStock < widget.entry!.quantity;
    final isWrittenOff = widget.entry != null && widget.entry!.quantity > 0;
    final total = currentQty * widget.item.costPerUnit;
    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );

    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isWrittenOff
            ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.04)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: widget.isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.zero,
        border: Border(left: borderSide, right: borderSide, bottom: borderSide),
      ),
      child: Row(
        children: [
          // 1. Наименование и бейдж ед. изм.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isWrittenOff)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          PhosphorIconsRegular.checkCircle,
                          size: 14,
                          color: AppColors.success,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        widget.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              isWrittenOff ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 12,
                          color:
                              isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ),
                    if (isStockLow) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Превышает остаток!',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 2. Остаток на складе
          SizedBox(
            width: 85,
            child: Text(
              '${_fmt(widget.item.currentStock)} $unit',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Поле ввода «К списанию» (прямоугольное, без suffixText, по центру)
          SizedBox(
            width: 85,
            height: 34,
            child: TextField(
              controller: _qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              decoration: buildBulkInputDecoration(
                context,
                '0',
                isHintOnly: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
              ),
              onChanged: (val) {
                final parsed =
                    double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                widget.onQuantityChanged(widget.item, parsed);
              },
            ),
          ),
          const SizedBox(width: 8),

          // 4. Себестоимость
          SizedBox(
            width: 95,
            child: Text(
              '${widget.item.costPerUnit.toStringAsFixed(2)} ${widget.currency}',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. Сумма
          SizedBox(
            width: 85,
            child: Text(
              total > 0
                  ? '${total.toStringAsFixed(2)} ${widget.currency}'
                  : '—',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: total > 0
                    ? (isDark ? AppColors.darkText : AppColors.lightText)
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
