import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          runSpacing: 12.0,
          children: [
            _buildPill(
              context: context,
              label: 'Все',
              value: 'all',
              isDark: isDark,
            ),
            _buildPill(
              context: context,
              label: 'Сырье для кухни',
              value: 'raw',
              isDark: isDark,
            ),
            _buildPill(
              context: context,
              label: 'Витрина',
              value: 'retail',
              isDark: isDark,
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: onToggleExpandAll,
              icon: Icon(
                isExpandedAll ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                size: 16,
              ),
              label: Text(
                isExpandedAll ? 'Свернуть все' : 'Развернуть все',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isSelected = currentFilter == value;

    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
