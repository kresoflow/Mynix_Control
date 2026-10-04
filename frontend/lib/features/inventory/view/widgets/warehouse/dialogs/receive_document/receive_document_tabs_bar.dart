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

class ReceiveDocumentTabsBar extends StatelessWidget {
  final int tabIndex; // 1 = Товары витрины, 2 = Сырье
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddRow;

  const ReceiveDocumentTabsBar({
    super.key,
    required this.tabIndex,
    required this.onTabSelected,
    required this.onAddRow,
  });

  static const _tabs = [
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
          // 1. Селектор режимов (Пилюли как в BulkAdd)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: BorderRadius.circular(10),
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

          // 2. Информационный статус-лейбл
          Expanded(
            child: Text(
              tabIndex == 1
                  ? 'Оприходование фасованных товаров витрины со штрихкодами и розничной ценой'
                  : 'Оприходование базового сырья и полуфабрикатов для списания по техкартам',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 3. Фиксированная кнопка добавления строки в правом верхнем тулбаре
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
}
