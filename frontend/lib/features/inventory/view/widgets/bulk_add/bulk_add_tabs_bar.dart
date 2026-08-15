import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class BulkAddTabsBar extends StatelessWidget {
  final int tabIndex;
  final String categoryType;
  final Function(int) onTabSelected;
  final Function(String) onCategoryTypeChanged;
  final VoidCallback onAddRow;

  const BulkAddTabsBar({
    super.key,
    required this.tabIndex,
    required this.categoryType,
    required this.onTabSelected,
    required this.onCategoryTypeChanged,
    required this.onAddRow,
  });

  static const tabLabels = ['Блюда', 'Товары витрины', 'Сырьё', 'Папки'];
  static const tabIcons = [
    PhosphorIconsRegular.cookingPot,
    PhosphorIconsRegular.storefront,
    PhosphorIconsRegular.leaf,
    PhosphorIconsRegular.folderPlus,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabLabels.length, (i) {
                final selected = tabIndex == i;
                return GestureDetector(
                  onTap: () => onTabSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.brandPrimary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tabIcons[i],
                          size: 16,
                          color: selected
                              ? Colors.white
                              : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabLabels[i],
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                            color: selected
                                ? Colors.white
                                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          if (tabIndex == 3) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPillTab('Для блюд', 'dish', isDark),
                  _buildPillTab('Для витрины', 'retail', isDark),
                  _buildPillTab('Для сырья', 'ingredient', isDark),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          TextButton.icon(
            onPressed: onAddRow,
            icon: const Icon(PhosphorIconsRegular.plus, size: 16),
            label: const Text('Строка'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab(String label, String value, bool isDark) {
    final selected = categoryType == value;

    return GestureDetector(
      onTap: () => onCategoryTypeChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ),
      ),
    );
  }
}
