// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';

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
            ? const BorderRadius.vertical(bottom: Radius.circular(AppRadii.input))
            : BorderRadius.zero,
        border: Border(left: borderSide, right: borderSide, bottom: borderSide),
      ),
      child: Row(
        children: [
          // 1. Порядковый номер
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Номенклатура + бейдж ед. изм. + категория сырья/витрины
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isFilled)
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
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              isFilled ? FontWeight.w700 : FontWeight.w600,
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
                        borderRadius: AppRadii.radiusXs,
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
                    const SizedBox(width: 6),
                    Text(
                      isRetail ? 'Витрина' : 'Сырье',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. Статус заполнения
          SizedBox(
            width: 90,
            child: Center(
              child: isFilled
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: isDark ? 0.16 : 0.10,
                        ),
                        borderRadius: AppRadii.badgeRadius,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.check,
                            size: 11,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Введено',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      '—',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Поле ввода «Факт» (прямоугольное, без suffixText, по центру)
          SizedBox(
            width: 85,
            height: 34,
            child: TextField(
              controller: controller,
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
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
