import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StockLowInventoryWidget extends StatelessWidget {
  final List<Ingredient> lowStockItems;
  final VoidCallback onReceiveTap;

  const StockLowInventoryWidget({
    super.key,
    required this.lowStockItems,
    required this.onReceiveTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topLow = lowStockItems.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: lowStockItems.isNotEmpty
              ? AppColors.danger.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (lowStockItems.isNotEmpty ? AppColors.danger : AppColors.success)
                      .withValues(alpha: 0.15),
                  borderRadius: AppRadii.inputRadius,
                ),
                child: Icon(
                  lowStockItems.isNotEmpty
                      ? PhosphorIconsRegular.warningCircle
                      : PhosphorIconsRegular.checkCircle,
                  color: lowStockItems.isNotEmpty ? AppColors.danger : AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Требуют закупки',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      lowStockItems.isNotEmpty
                          ? '${lowStockItems.length} поз. ниже минимума'
                          : 'Все запасы в норме',
                      style: AppTextStyles.caption.copyWith(
                        color: lowStockItems.isNotEmpty
                            ? AppColors.danger
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topLow.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Дефицита на складе нет',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            )
          else ...[
            ...topLow.map((item) {
              final stockStr = UnitFormatter.formatAmount(item.currentStock, item.unit);
              final minStr = UnitFormatter.formatAmount(item.minStockAlert, item.unit);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: AppRadii.inputRadius,
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Остаток: $stockStr • Мин: $minStr',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.danger,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(
                label: 'Оформить приход',
                icon: PhosphorIconsRegular.plusCircle,
                onPressed: onReceiveTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
