// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ==============================================================================
// 2. СТРОКА ТОВАРА КАТЕГОРИИ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Строка номенклатуры в аккордеоне категории для ввода факта.
class BlindInventoryCategoryItemRow extends StatelessWidget {
  final Ingredient item;
  final int index;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool isLast;

  const BlindInventoryCategoryItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.controller,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = UnitFormatter.format(item.unit);
    final isRetail = item.attributes?['is_retail'] == true;
    final isFilled = controller.text.trim().isNotEmpty;
    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isFilled
            ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.08 : 0.04)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.zero,
        border: Border(left: borderSide, right: borderSide, bottom: borderSide),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
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
                Text(
                  isRetail ? 'Витрина' : 'Сырье',
                  style: AppTextStyles.caption.copyWith(
                    color:
                        isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            height: 32,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: AppTextStyles.monoBold.copyWith(
                fontSize: 12,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: 'Факт',
                suffixText: unit,
                suffixStyle: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: borderSide,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: borderSide,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.brandPrimary),
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
