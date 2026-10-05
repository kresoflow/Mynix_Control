// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'write_off_items_table.dart';

// ==============================================================================
// 2. СТРОКА ТОВАРА ВНУТРИ КАТЕГОРИИ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Строка номенклатуры в аккордеоне категории с полем ввода списания.
class WriteOffCategoryItemRow extends StatelessWidget {
  final Ingredient item;
  final WriteOffItemEntry? entry;
  final String currency;
  final void Function(Ingredient item, double qty) onQuantityChanged;

  const WriteOffCategoryItemRow({
    super.key,
    required this.item,
    required this.entry,
    required this.currency,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = UnitFormatter.format(item.unit);
    final isStockLow = entry != null && item.currentStock < entry!.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'В наличии: ${UnitFormatter.formatAmount(item.currentStock, item.unit)}',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.costPerUnit.toStringAsFixed(2)} $currency/$unit',
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                    if (isStockLow) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Превышает остаток!',
                        style: TextStyle(
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
          SizedBox(
            width: 100,
            height: 32,
            child: TextField(
              controller: entry?.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: unit,
                suffixStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                onQuantityChanged(item, parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
