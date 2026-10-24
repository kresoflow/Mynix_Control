// ==============================================================================
// МОДУЛЬ: Склад и Меню / Секция опций и модификаторов блюда
// ДОМЕН: lib/features/inventory/view/widgets/menu_item/menu_item_options_section.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Переключатель и секции вариаций размеров и групп модификаторов:
// 1. Адаптивный переключатель (SwitchListTile) с поддержкой темной/светлой темы.
// 2. Отображает MenuItemVariationsSection и MenuItemModifierGroupsSection.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'menu_item_variations_section.dart';
import 'menu_item_modifier_groups_section.dart';

class MenuItemOptionsSection extends StatelessWidget {
  final bool hasModifiers;
  final ValueChanged<bool> onToggleModifiers;
  final List<Map<String, dynamic>> variations;
  final VoidCallback onAddVariation;
  final ValueChanged<int> onRemoveVariation;
  final List<Map<String, dynamic>> modifierGroups;
  final VoidCallback onAddGroup;
  final ValueChanged<int> onRemoveGroup;
  final ValueChanged<int> onAddOption;
  final void Function(int groupIndex, int optionIndex) onRemoveOption;
  final void Function(int groupIndex, bool required) onToggleRequired;

  const MenuItemOptionsSection({
    super.key,
    required this.hasModifiers,
    required this.onToggleModifiers,
    required this.variations,
    required this.onAddVariation,
    required this.onRemoveVariation,
    required this.modifierGroups,
    required this.onAddGroup,
    required this.onRemoveGroup,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onToggleRequired,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : AppColors.lightBg,
            borderRadius: AppRadii.cardRadius,
          ),
          child: SwitchListTile(
            title: Text(
              'Размеры или модификаторы (опции)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            value: hasModifiers,
            onChanged: onToggleModifiers,
            activeThumbColor: AppColors.brandPrimary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
          ),
        ),
        if (hasModifiers) ...[
          const SizedBox(height: 20),
          MenuItemVariationsSection(
            variations: variations,
            onAddVariation: onAddVariation,
            onRemoveVariation: onRemoveVariation,
          ),
          const SizedBox(height: 20),
          MenuItemModifierGroupsSection(
            modifierGroups: modifierGroups,
            onAddGroup: onAddGroup,
            onRemoveGroup: onRemoveGroup,
            onAddOption: onAddOption,
            onRemoveOption: onRemoveOption,
            onToggleRequired: onToggleRequired,
          ),
        ],
      ],
    );
  }
}
