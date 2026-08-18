import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_shadows.dart';

class BulkAddTabsBar extends StatelessWidget {
  final int tabIndex;
  final String categoryType;
  final Function(int) onTabSelected;
  final Function(String) onCategoryTypeChanged;
  final VoidCallback onAddRow;
  final ValueChanged<String>? onLoadPreset;

  const BulkAddTabsBar({
    super.key,
    required this.tabIndex,
    required this.categoryType,
    required this.onTabSelected,
    required this.onCategoryTypeChanged,
    required this.onAddRow,
    this.onLoadPreset,
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
              color: isDark ? const Color(0xFF10141D) : AppColors.lightBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabLabels.length, (i) {
                final selected = tabIndex == i;
                return GestureDetector(
                  onTap: () => onTabSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandPrimary : Colors.transparent,
                      borderRadius: AppRadii.tabRadius,
                      boxShadow: selected ? AppShadows.tabGlow(AppColors.brandPrimary) : null,
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
          if (onLoadPreset != null && (tabIndex == 0 || tabIndex == 2 || tabIndex == 3)) ...[
            PopupMenuButton<String>(
              tooltip: 'Загрузить готовый шаблон данных',
              onSelected: onLoadPreset,
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'fastfood',
                  child: Row(
                    children: [
                      Text('🍔', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('Шаблон «Фастфуд»'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'restaurant',
                  child: Row(
                    children: [
                      Text('🍝', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('Шаблон «Ресторан»'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF10141D) : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.cards,
                      size: 16,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Пресеты',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIconsRegular.caretDown,
                      size: 12,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (tabIndex == 3) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10141D) : AppColors.lightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: AppRadii.tabRadius,
          boxShadow: selected ? AppShadows.tabGlow(AppColors.brandPrimary) : null,
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
