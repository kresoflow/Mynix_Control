// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';

// ==============================================================================
// 2. СТРОКА ПОЗИЦИИ ИНВЕНТАРИЗАЦИИ (СВЕРКА ФАКТА И УЧЕТА)
// ==============================================================================
/// [ИНВАРИАНТ] Строка инвентаризационной описи с расчетом отклонений и сумм.
class DocumentDetailInventoryRow extends StatelessWidget {
  final InventoryDocumentItem item;
  final int index;
  final bool isDark;

  const DocumentDetailInventoryRow({
    super.key,
    required this.item,
    required this.index,
    required this.isDark,
  });

  static String formatQuantity(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final name = item.ingredientName ??
        item.retailProductName ??
        'Позиция #${item.id ?? index + 1}';
    final exp = item.expectedQuantity ?? item.quantity;
    final diff = item.quantity - exp;
    final diffAmount = diff * item.pricePerUnit;
    final isSurplus = diff > 0.001;
    final isShortage = diff < -0.001;

    final diffColor = isSurplus
        ? AppColors.success
        : (isShortage
            ? AppColors.danger
            : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext));
    final diffText = isSurplus
        ? '+${formatQuantity(diff)} (+${diffAmount.toStringAsFixed(0)} с)'
        : (isShortage
            ? '${formatQuantity(diff)} (${diffAmount.toStringAsFixed(0)} с)'
            : '0.00 (0 с)');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatQuantity(exp),
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                fontSize: 13,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatQuantity(item.quantity),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: AppRadii.radiusXs,
                ),
                child: Text(
                  diffText,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: diffColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 3. СТАНДАРТНАЯ СТРОКА НАКЛАДНОЙ / СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Строка приходной или расходной накладной (цена, количество, сумма).
class DocumentDetailStandardRow extends StatelessWidget {
  final InventoryDocumentItem item;
  final int index;
  final bool isDark;

  const DocumentDetailStandardRow({
    super.key,
    required this.item,
    required this.index,
    required this.isDark,
  });

  static String formatQuantity(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final name = item.ingredientName ??
        item.retailProductName ??
        'Позиция #${item.id ?? index + 1}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatQuantity(item.quantity),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.pricePerUnit.toCurrency(context),
              textAlign: TextAlign.right,
              style: AppTextStyles.caption,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.totalPrice.toCurrency(context),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
