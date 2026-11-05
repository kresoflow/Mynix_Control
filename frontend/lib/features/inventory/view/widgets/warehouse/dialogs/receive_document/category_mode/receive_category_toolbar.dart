// ==============================================================================
// МОДУЛЬ: Склад / Панель инструментов каталога прихода по категориям
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/category_mode/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

/// Фильтр отображения позиций в режиме категорий
enum ReceiveCategoryFilter {
  /// Все позиции склада
  all,

  /// Только товары с дефицитом / низким остатком
  onlyDeficit,

  /// Только позиции, добавленные в текущую накладную
  inReceipt,
}

/// Панель инструментов режима категорий: поиск, быстрые фильтры и кнопка сворачивания
class ReceiveCategoryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ReceiveCategoryFilter activeFilter;
  final ValueChanged<ReceiveCategoryFilter> onFilterChanged;
  final int deficitCount;
  final int inReceiptCount;
  final bool isAllExpanded;
  final VoidCallback onToggleExpandAll;

  const ReceiveCategoryToolbar({
    super.key,
    required this.searchController,
    this.searchFocusNode,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.deficitCount,
    required this.inReceiptCount,
    required this.isAllExpanded,
    required this.onToggleExpandAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Поиск по номенклатуре
          SizedBox(
            width: 240,
            child: AppSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              hintText: 'Поиск по складу...',
              size: AppSearchFieldSize.sm,
              autoFocus: true,
              onChanged: onSearchChanged,
              onClear: () => onSearchChanged(''),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Фильтр "Все"
          AppFilterChip(
            label: 'Все',
            isSelected: activeFilter == ReceiveCategoryFilter.all,
            size: AppFilterChipSize.sm,
            onTap: () => onFilterChanged(ReceiveCategoryFilter.all),
          ),
          const SizedBox(width: 6),

          // 3. Фильтр "Дефицит"
          AppFilterChip(
            label: 'Дефицит',
            count: deficitCount > 0 ? deficitCount : null,
            isSelected: activeFilter == ReceiveCategoryFilter.onlyDeficit,
            activeColor: AppColors.danger,
            size: AppFilterChipSize.sm,
            onTap: () => onFilterChanged(ReceiveCategoryFilter.onlyDeficit),
          ),
          const SizedBox(width: 6),

          // 4. Фильтр "В накладной"
          AppFilterChip(
            label: 'В накладной',
            count: inReceiptCount > 0 ? inReceiptCount : null,
            isSelected: activeFilter == ReceiveCategoryFilter.inReceipt,
            activeColor: AppColors.brandPrimary,
            size: AppFilterChipSize.sm,
            onTap: () => onFilterChanged(ReceiveCategoryFilter.inReceipt),
          ),

          const Spacer(),

          // 5. Кнопка Развернуть/Свернуть всё
          AppExpandAllButton(
            isExpanded: isAllExpanded,
            onToggle: onToggleExpandAll,
            mode: AppExpandAllMode.full,
          ),
        ],
      ),
    );
  }
}
