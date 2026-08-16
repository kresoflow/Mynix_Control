import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

class DialogModifierGroupsList extends StatelessWidget {
  final List<dynamic> modifierGroups;
  final Map<int, Set<int>> selectedModifiers;
  final Function(int groupIndex, int modifierIndex, bool isSelected) onToggleModifier;

  const DialogModifierGroupsList({
    super.key,
    required this.modifierGroups,
    required this.selectedModifiers,
    required this.onToggleModifier,
  });

  @override
  Widget build(BuildContext context) {
    if (modifierGroups.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(modifierGroups.length, (g) {
        final group = modifierGroups[g];
        final mods = group['modifiers'] as List<dynamic>;
        final selectedSet = selectedModifiers[g] ?? {};

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group['name'],
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  if (group['required'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Обязательно',
                        style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: List.generate(mods.length, (mIndex) {
                    final mod = mods[mIndex];
                    final isSelected = selectedSet.contains(mIndex);
                    final isLast = mIndex == mods.length - 1;

                    return Column(
                      children: [
                        CheckboxListTile(
                          activeColor: AppColors.brandPrimary,
                          checkColor: Colors.black,
                          title: Text(
                            mod['name'],
                            style: AppTextStyles.body.copyWith(
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            mod['price'] != null && mod['price'] != 0
                                ? '+${(mod['price'] as num?)?.toDouble().toCurrency(context) ?? '0'}'
                                : '',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (val) => onToggleModifier(g, mIndex, val == true),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
