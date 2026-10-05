// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'blind_inventory_category_item_row.dart';

// ==============================================================================
// 2. АККОРДЕОН КАТЕГОРИИ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Аккордеон категории инвентаризации с подсчетом заполненности.
class BlindInventoryCategoryAccordion extends StatelessWidget {
  final String categoryName;
  final List<Ingredient> items;
  final Map<int, TextEditingController> controllers;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onChanged;

  const BlindInventoryCategoryAccordion({
    super.key,
    required this.categoryName,
    required this.items,
    required this.controllers,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int filledCount = 0;
    for (final it in items) {
      if (controllers[it.id]?.text.trim().isNotEmpty == true) {
        filledCount++;
      }
    }
    final isAllFilled = items.isNotEmpty && filledCount == items.length;

    final iconString = context.select<CategoryBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is CategoryLoaded) {
        return state.categories
            .where((c) => c.name == categoryName)
            .firstOrNull
            ?.getInheritedIcon(state.categories);
      }
      return null;
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded
              ? AppColors.brandPrimary.withValues(alpha: 0.5)
              : (isAllFilled
                  ? AppColors.success.withValues(alpha: 0.4)
                  : (filledCount > 0
                      ? AppColors.brandPrimary.withValues(alpha: 0.25)
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder))),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (iconString != null && iconString.isNotEmpty)
                    IconHelper.buildIcon(
                      iconString,
                      size: 18,
                      color: isExpanded
                          ? AppColors.brandPrimary
                          : (isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext),
                    )
                  else
                    Icon(
                      PhosphorIconsRegular.folder,
                      size: 18,
                      color: isExpanded
                          ? AppColors.brandPrimary
                          : (isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isAllFilled
                          ? AppColors.success
                              .withValues(alpha: isDark ? 0.16 : 0.10)
                          : (filledCount > 0
                              ? AppColors.brandPrimary
                                  .withValues(alpha: isDark ? 0.16 : 0.10)
                              : (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightBg)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Посчитано: $filledCount из ${items.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAllFilled
                            ? AppColors.success
                            : (filledCount > 0
                                ? AppColors.brandPrimary
                                : (isDark
                                    ? AppColors.darkSubtext
                                    : AppColors.lightSubtext)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? PhosphorIconsRegular.caretUp
                        : PhosphorIconsRegular.caretDown,
                    size: 14,
                    color:
                        isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (!controllers.containsKey(item.id)) {
                    controllers[item.id] = TextEditingController();
                  }

                  return BlindInventoryCategoryItemRow(
                    item: item,
                    index: index,
                    controller: controllers[item.id]!,
                    onChanged: onChanged,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
