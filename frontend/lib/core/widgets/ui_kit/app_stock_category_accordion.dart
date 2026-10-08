// ==============================================================================
// УНИФИЦИРОВАННЫЙ СКЛАДСКОЙ АККОРДЕОН (APP STOCK CATEGORY ACCORDION)
// ==============================================================================
//
// [ИНВАРИАНТ] Золотой стандарт Приходной накладной для категорий склада.
// Поддерживает бейджи дефицита ("29 мало"), счетчик позиций, сумму категории
// и встраиваемую таблицу товаров.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// [UI-KIT] Складской аккордеон категории (стандарт Приходки и Инвентаризации)
class AppStockCategoryAccordion extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? leading;
  final int? itemCount;
  final int? lowStockCount;
  final double? totalSum;
  final String currency;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget? child;
  final bool isHighlighted;
  final bool isSubcategory;
  final Widget? trailingBadge;

  const AppStockCategoryAccordion({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.itemCount,
    this.lowStockCount,
    this.totalSum,
    this.currency = 'с',
    required this.isExpanded,
    required this.onExpansionChanged,
    this.child,
    this.isHighlighted = false,
    this.isSubcategory = false,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final hasActiveSum = totalSum != null && totalSum! > 0;
    final activeBorderColor = isExpanded
        ? AppColors.brandPrimary.withValues(alpha: 0.5)
        : (hasActiveSum || isHighlighted
            ? AppColors.brandPrimary.withValues(alpha: 0.25)
            : border);

    final borderRadius = isExpanded && child == null
        ? (isSubcategory
            ? BorderRadius.circular(8)
            : const BorderRadius.vertical(top: Radius.circular(10)))
        : BorderRadius.circular(isSubcategory ? 8 : 10);

    return Container(
      margin: EdgeInsets.only(
        left: isSubcategory ? 14 : 0,
        bottom: isExpanded ? (child != null ? 8 : 0) : (isSubcategory ? 6 : 8),
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: borderRadius,
        border: Border.all(color: activeBorderColor),
        boxShadow: isExpanded && !isSubcategory
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Заголовок категории ───
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            borderRadius: borderRadius,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSubcategory ? 12 : 16,
                vertical: isSubcategory ? 8 : 12,
              ),
              child: Row(
                children: [
                  if (leading != null)
                    leading!
                  else
                    Icon(
                      icon ??
                          (isSubcategory
                              ? PhosphorIconsRegular.folder
                              : PhosphorIconsRegular.folderSimple),
                      size: isSubcategory ? 16 : 20,
                      color: isExpanded
                          ? AppColors.brandPrimary
                          : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    ),
                  SizedBox(width: isSubcategory ? 8 : 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: isSubcategory ? 13 : 14,
                        fontWeight:
                            isSubcategory ? FontWeight.w600 : FontWeight.w700,
                        color: isExpanded
                            ? AppColors.brandPrimary
                            : (isDark ? AppColors.darkText : AppColors.lightText),
                      ),
                    ),
                  ),

                  // Кастомный бейдж (например: «3 к приходу» или «2 списано»)
                  if (trailingBadge != null) ...[
                    trailingBadge!,
                    const SizedBox(width: 8),
                  ],

                  // Бейдж дефицита (красный)
                  if (lowStockCount != null && lowStockCount! > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$lowStockCount мало',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Сумма по категории
                  if (hasActiveSum) ...[
                    Text(
                      '${totalSum!.toStringAsFixed(2)} $currency',
                      style: AppTextStyles.monoBold.copyWith(
                        fontSize: 12,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Счетчик позиций
                  if (itemCount != null) ...[
                    Text(
                      '$itemCount поз.',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Стрелка раскрытия
                  Icon(
                    isExpanded
                        ? PhosphorIconsRegular.caretDown
                        : PhosphorIconsRegular.caretRight,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ],
              ),
            ),
          ),

          // ─── Раскрывающееся содержимое (таблица позиций) ───
          if (isExpanded && child != null) ...[
            Divider(height: 1, color: border.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: child!,
            ),
          ],
        ],
      ),
    );
  }
}
