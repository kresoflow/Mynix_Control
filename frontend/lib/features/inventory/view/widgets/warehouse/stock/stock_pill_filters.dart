import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StockPillFilters extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isExpandedAll;
  final VoidCallback onToggleExpandAll;
  final ValueChanged<String>? onSearchChanged;

  const StockPillFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.isExpandedAll,
    required this.onToggleExpandAll,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: AppFilterBar(
              spacing: 8.0,
              children: [
                AppFilterChip(
                  label: 'Все',
                  isSelected: currentFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                AppFilterChip(
                  label: 'Сырье для кухни',
                  icon: PhosphorIconsRegular.cookingPot,
                  isSelected: currentFilter == 'raw',
                  onTap: () => onFilterChanged('raw'),
                ),
                AppFilterChip(
                  label: 'Витрина',
                  icon: PhosphorIconsRegular.storefront,
                  isSelected: currentFilter == 'retail',
                  onTap: () => onFilterChanged('retail'),
                ),
                if (onSearchChanged != null)
                  AppSearchField(
                    mode: AppSearchMode.collapsible,
                    size: AppSearchFieldSize.sm,
                    hintText: 'Поиск остатков...',
                    onChanged: onSearchChanged,
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: onToggleExpandAll,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(8),
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
                    size: 14,
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
}
