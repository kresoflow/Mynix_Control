// ==============================================================================
// ВИДЖЕТ: Тулбар переключения режима накладной (Витрина / Сырье) и добавления строк
// ДОМЕН: features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'category_mode/receive_category_sync_adapter.dart';

class ReceiveDocumentTabsBar extends StatelessWidget {
  final int tabIndex; // 1 = Товары витрины, 2 = Сырье
  final ValueChanged<int> onTabSelected;
  final ReceiveViewMode viewMode;
  final ValueChanged<ReceiveViewMode> onViewModeChanged;
  final VoidCallback onAddRow;

  const ReceiveDocumentTabsBar({
    super.key,
    required this.tabIndex,
    required this.onTabSelected,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onAddRow,
  });

  static const _tabs = [
    (index: 0, label: 'Все', icon: PhosphorIconsRegular.stack),
    (index: 1, label: 'Товары витрины', icon: PhosphorIconsRegular.storefront),
    (index: 2, label: 'Сырьё', icon: PhosphorIconsRegular.leaf),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          // 1. Селектор типа номенклатуры (Витрина / Сырьё)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: AppRadii.inputRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _tabs.map((tab) {
                final selected = tabIndex == tab.index;
                return GestureDetector(
                  onTap: () => onTabSelected(tab.index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandPrimary : AppColors.transparent,
                      borderRadius: AppRadii.tabRadius,
                      boxShadow: selected ? AppShadows.tabGlow(AppColors.brandPrimary) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 16,
                          color: selected
                              ? AppColors.pureWhite
                              : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                            color: selected
                                ? AppColors.pureWhite
                                : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Сегментированный переключатель вида (По строкам / По категориям)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: AppRadii.inputRadius,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewPill(
                  label: 'По строкам',
                  icon: PhosphorIconsRegular.listDashes,
                  isSelected: viewMode == ReceiveViewMode.lines,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    onViewModeChanged(ReceiveViewMode.lines);
                  },
                  isDark: isDark,
                ),
                _buildViewPill(
                  label: 'По категориям',
                  icon: PhosphorIconsRegular.squaresFour,
                  isSelected: viewMode == ReceiveViewMode.categories,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    onViewModeChanged(ReceiveViewMode.categories);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 3. Информационный статус-лейбл
          Expanded(
            child: Text(
              viewMode == ReceiveViewMode.categories
                  ? 'Каталог категорий склада: пополнение остатков с контролем дефицита'
                  : (tabIndex == 0
                      ? 'Оприходование всей номенклатуры склада (смешанная накладная)'
                      : (tabIndex == 1
                          ? 'Оприходование товаров витрины со штрихкодами и розничной ценой'
                          : 'Оприходование базового сырья и полуфабрикатов по накладной')),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 4. Кнопка добавления строки (активна в режиме строк)
          if (viewMode == ReceiveViewMode.lines)
            AppButton.secondary(
              label: 'Строка',
              icon: PhosphorIconsRegular.plus,
              height: 36,
              onPressed: onAddRow,
            ),
        ],
      ),
    );
  }

  Widget _buildViewPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.pureWhite)
              : AppColors.transparent,
          borderRadius: AppRadii.badgeRadius,
          boxShadow: isSelected ? AppShadows.light : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.darkText : AppColors.lightText)
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
