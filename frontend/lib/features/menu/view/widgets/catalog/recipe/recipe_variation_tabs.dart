import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecipeVariationTabs extends StatelessWidget {
  final List<Map<String, dynamic>> variations;
  final int selectedIndex;
  final ValueChanged<int> onSelectVariation;
  final String currency;

  const RecipeVariationTabs({
    super.key,
    required this.variations,
    required this.selectedIndex,
    required this.onSelectVariation,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (variations.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.stack,
                size: 14,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              const SizedBox(width: 6),
              Text(
                'Вариации блюда () — выберите для настройки отдельной техкарты:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(variations.length, (idx) {
                final v = variations[idx];
                final name = v['name']?.toString() ?? 'Вариант ${idx + 1}';
                final price = (v['price'] as num?)?.toDouble() ?? 0.0;
                final isSelected = idx == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => onSelectVariation(idx),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandPrimary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPrimary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? PhosphorIconsBold.checkCircle : PhosphorIconsRegular.circle,
                            size: 14,
                            color: isSelected
                                ? AppColors.brandPrimary
                                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.brandPrimary
                                  : (isDark ? AppColors.darkText : AppColors.lightText),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandPrimary.withValues(alpha: 0.2)
                                  : (isDark ? AppColors.darkBg : AppColors.lightBg),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${price.toStringAsFixed(0)} $currency',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.brandPrimary
                                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
