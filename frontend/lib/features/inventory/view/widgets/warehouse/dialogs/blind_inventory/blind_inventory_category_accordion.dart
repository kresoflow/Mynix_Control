// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_stock_category_accordion.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ==============================================================================
// 2. АККОРДЕОН КАТЕГОРИИ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Заголовок категории инвентаризации с подсчетом заполненности (0 мс).
class BlindInventoryCategoryAccordion extends StatelessWidget {
  final String categoryName;
  final List<Ingredient> items;
  final Map<String, TextEditingController> controllers;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const BlindInventoryCategoryAccordion({
    super.key,
    required this.categoryName,
    required this.items,
    required this.controllers,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int filledCount = 0;
    for (final it in items) {
      if (controllers[it.uniqueKey]?.text.trim().isNotEmpty == true) {
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

    return AppStockCategoryAccordion(
      title: categoryName,
      leading: (iconString != null && iconString.isNotEmpty)
          ? IconHelper.buildIcon(
              iconString,
              size: 18,
              color: isExpanded
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            )
          : null,
      isExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      itemCount: items.length,
      isHighlighted: filledCount > 0,
      trailingBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isAllFilled
              ? AppColors.success.withValues(alpha: isDark ? 0.16 : 0.10)
              : (filledCount > 0
                  ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10)
                  : (isDark ? AppColors.darkSurface : AppColors.lightBg)),
          borderRadius: AppRadii.badgeRadius,
        ),
        child: Text(
          'Посчитано: $filledCount из ${items.length}',
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isAllFilled
                ? AppColors.success
                : (filledCount > 0
                    ? AppColors.brandPrimary
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ),
        ),
      ),
      child: null, // [ОПТИМИЗАЦИЯ] child=null для плоской виртуализации (0 мс)
    );
  }
}

// ==============================================================================
// 3. ШАПКА ТАБЛИЦЫ ВНУТРИ КАТЕГОРИИ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Шапка таблицы колонок внутри категории инвентаризации.
class BlindInventoryCategoryTableHeader extends StatelessWidget {
  const BlindInventoryCategoryTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        border: Border(
          left: borderSide,
          right: borderSide,
          bottom: borderSide,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('№', textAlign: TextAlign.center, style: style),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('Номенклатура', style: style)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text('Статус', textAlign: TextAlign.center, style: style),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text('Факт', textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }
}
