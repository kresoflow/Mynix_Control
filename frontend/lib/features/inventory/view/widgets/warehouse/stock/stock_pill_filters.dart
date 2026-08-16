import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StockPillFilters extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isExpandedAll;
  final VoidCallback onToggleExpandAll;

  const StockPillFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.isExpandedAll,
    required this.onToggleExpandAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildPill(
                  label: 'Все',
                  value: 'all',
                  isDark: isDark,
                ),
                _buildPill(
                  label: 'Сырье для кухни',
                  value: 'raw',
                  isDark: isDark,
                ),
                _buildPill(
                  label: 'Витрина',
                  value: 'retail',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onToggleExpandAll,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpandedAll
                        ? PhosphorIconsRegular.caretUp
                        : PhosphorIconsRegular.caretDown,
                    size: 15,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExpandedAll ? 'Свернуть все' : 'Развернуть все',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isSelected = currentFilter == value;

    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
