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
// 2. РЕЖИМ ФИЛЬТРАЦИИ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Режимы фильтрации позиций в ревизии склада.
enum BlindInventoryFilter {
  /// Все позиции номенклатуры
  all,

  /// Только незаполненные (осталось пересчитать)
  unfilled,

  /// Только заполненные (уже внесенные)
  filled,
}

// ==============================================================================
// 3. ТУЛБАР ФИЛЬТРАЦИИ И ПОИСКА ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Панель инструментов инвентаризации с поиском, чипами и кнопкой сворачивания.
class BlindInventoryToolbar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final BlindInventoryFilter activeFilter;
  final ValueChanged<BlindInventoryFilter> onFilterChanged;
  final int unfilledCount;
  final int filledCount;
  final bool isAllExpanded;
  final VoidCallback onToggleExpandAll;

  const BlindInventoryToolbar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.unfilledCount,
    required this.filledCount,
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
            size: AppSearchFieldSize.sm,
            hintText: 'Поиск номенклатуры...',
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 8),

        // ─── 2. Фильтр "Все" ───
        AppFilterChip(
          label: 'Все',
          isSelected: activeFilter == BlindInventoryFilter.all,
          size: AppFilterChipSize.sm,
          onTap: () => onFilterChanged(BlindInventoryFilter.all),
        ),
        const SizedBox(width: 6),

        // ─── 3. Фильтр "Не посчитано" ───
        AppFilterChip(
          label: 'Не посчитано',
          count: unfilledCount > 0 ? unfilledCount : null,
          isSelected: activeFilter == BlindInventoryFilter.unfilled,
          activeColor: AppColors.warning,
          size: AppFilterChipSize.sm,
          onTap: () => onFilterChanged(BlindInventoryFilter.unfilled),
        ),
        const SizedBox(width: 6),

        // ─── 4. Фильтр "Посчитано" ───
        AppFilterChip(
          label: 'Посчитано',
          count: filledCount > 0 ? filledCount : null,
          isSelected: activeFilter == BlindInventoryFilter.filled,
          activeColor: AppColors.brandPrimary,
          size: AppFilterChipSize.sm,
          onTap: () => onFilterChanged(BlindInventoryFilter.filled),
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
