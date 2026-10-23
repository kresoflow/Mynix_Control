// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'write_off_items_table.dart';

// ==============================================================================
// 2. СТРОКА ТАБЛИЦЫ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Строка позиции акта списания со строгой табулярной сеткой.
class WriteOffItemRow extends StatelessWidget {
  final WriteOffItemEntry entry;
  final int index;
  final String currency;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  const WriteOffItemRow({
    super.key,
    required this.entry,
    required this.index,
    required this.currency,
    required this.onRemove,
    required this.onChanged,
  });

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    final str = v.toStringAsFixed(3);
    final trimmed = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = UnitFormatter.format(entry.item.unit);
    final isStockLow = entry.item.currentStock < entry.quantity;
    final isRetail = entry.item.attributes?['is_retail'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: WriteOffItemsTable.colNumWidth,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Text(
                  isStockLow
                      ? 'Внимание: превышает остаток склада!'
                      : (isRetail ? 'Витрина' : 'Сырье'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isStockLow ? FontWeight.w700 : FontWeight.w500,
                    color: isStockLow
                        ? AppColors.danger
                        : (isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: WriteOffItemsTable.colStockWidth,
            child: Text(
              '${_fmt(entry.item.currentStock)} $unit',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: WriteOffItemsTable.colQtyWidth,
            height: 34,
            child: TextField(
              controller: entry.controller,
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
                entry.quantity =
                    double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: WriteOffItemsTable.colCostWidth,
            child: Text(
              '${entry.cost.toStringAsFixed(2)} $currency',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: WriteOffItemsTable.colTotalWidth,
            child: Text(
              '${entry.total.toStringAsFixed(2)} $currency',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: entry.total > 0
                    ? (isDark ? AppColors.darkText : AppColors.lightText)
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: WriteOffItemsTable.colActionWidth,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.trash,
                  size: 16,
                  color: AppColors.danger,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                tooltip: 'Удалить строку',
                onPressed: () => onRemove(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
