// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_filter_chip.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';

// ==============================================================================
// 2. РЕЖИМ ФИЛЬТРАЦИИ КАТАЛОГА СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Режим фильтрации позиций в каталоге списания по категориям.
enum WriteOffCategoryFilter {
  /// Все позиции номенклатуры склада
  all,

  /// Только позиции, добавленные в текущий акт списания
  inAct,

  /// Только позиции с положительным остатком на складе
  inStock,
}

// ==============================================================================
// 3. ТУЛБАР ФИЛЬТРАЦИИ И ПОИСКА СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Панель инструментов каталога списания с поиском, чипами и кнопкой сворачивания.
class WriteOffCategoryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final WriteOffCategoryFilter activeFilter;
  final ValueChanged<WriteOffCategoryFilter> onFilterChanged;
  final int inActCount;
  final int inStockCount;
  final bool isAllExpanded;
  final VoidCallback onToggleExpandAll;

  const WriteOffCategoryToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.inActCount,
    required this.inStockCount,
    required this.isAllExpanded,
    required this.onToggleExpandAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // ─── 1. Поиск номенклатуры ───
        Expanded(
          child: AppSearchField(
            controller: searchController,
            size: AppSearchFieldSize.sm,
            hintText: 'Фильтр позиций...',
            onChanged: onSearchChanged,
            onClear: () => onSearchChanged(''),
          ),
        ),
        const SizedBox(width: 8),

        // ─── 2. Фильтр "Все" ───
        AppFilterChip(
          label: 'Все',
          isSelected: activeFilter == WriteOffCategoryFilter.all,
          size: AppFilterChipSize.sm,
          onTap: () => onFilterChanged(WriteOffCategoryFilter.all),
        ),
        const SizedBox(width: 6),

        // ─── 3. Фильтр "В акте" ───
        AppFilterChip(
          label: 'В акте',
          count: inActCount > 0 ? inActCount : null,
          isSelected: activeFilter == WriteOffCategoryFilter.inAct,
          activeColor: AppColors.brandPrimary,
          size: AppFilterChipSize.sm,
          onTap: () => onFilterChanged(WriteOffCategoryFilter.inAct),
        ),
        const SizedBox(width: 6),

        // ─── 4. Фильтр "В наличии" ───
        AppFilterChip(
          label: 'В наличии',
          count: inStockCount > 0 ? inStockCount : null,
          isSelected: activeFilter == WriteOffCategoryFilter.inStock,
          activeColor: AppColors.success,
          size: AppFilterChipSize.sm,
          onTap: () => onFilterChanged(WriteOffCategoryFilter.inStock),
        ),
        const SizedBox(width: 8),

        // ─── 5. Кнопка Развернуть/Свернуть всё ───
        InkWell(
          onTap: onToggleExpandAll,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAllExpanded
                      ? PhosphorIconsRegular.arrowsInSimple
                      : PhosphorIconsRegular.arrowsOutSimple,
                  size: 15,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                const SizedBox(width: 5),
                Text(
                  isAllExpanded ? 'Свернуть' : 'Развернуть',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
