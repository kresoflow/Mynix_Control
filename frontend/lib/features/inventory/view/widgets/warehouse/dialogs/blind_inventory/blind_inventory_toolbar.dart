// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

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
  final FocusNode? searchFocusNode;

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
    this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ─── 1. Поиск номенклатуры ───
        Expanded(
          child: AppSearchField(
            focusNode: searchFocusNode,
            size: AppSearchFieldSize.sm,
            hintText: 'Поиск номенклатуры...',
            autoFocus: true,
            onChanged: onSearchChanged,
            onClear: () => onSearchChanged(''),
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
        AppExpandAllButton(
          isExpanded: isAllExpanded,
          onToggle: onToggleExpandAll,
          mode: AppExpandAllMode.full,
        ),
      ],
    );
  }
}
