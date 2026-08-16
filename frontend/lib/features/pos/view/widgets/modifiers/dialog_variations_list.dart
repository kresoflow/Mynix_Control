import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DialogVariationsList extends StatelessWidget {
  final List<dynamic> variations;
  final double basePrice;
  final double additionalModifiersPrice;
  final ValueChanged<int> onSelectVariation;

  const DialogVariationsList({
    super.key,
    required this.variations,
    required this.basePrice,
    required this.additionalModifiersPrice,
    required this.onSelectVariation,
  });

  @override
  Widget build(BuildContext context) {
    if (variations.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Вариации (кликните для добавления)',
          style: AppTextStyles.h3.copyWith(
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(variations.length, (index) {
            final v = variations[index];
            final varPrice = (v['price'] as num?)?.toDouble() ?? 0.0;
            final finalPrice = varPrice + additionalModifiersPrice;
            final isLast = index == variations.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: InkWell(
                onTap: () => onSelectVariation(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          v['name'],
                          style: AppTextStyles.body.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        finalPrice.toCurrency(context),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(PhosphorIconsRegular.plusCircle, color: AppColors.brandPrimary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
