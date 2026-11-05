import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StockPillFilters extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isExpandedAll;
  final VoidCallback onToggleExpandAll;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;

  const StockPillFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.isExpandedAll,
    required this.onToggleExpandAll,
    this.onSearchChanged,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: AppFilterBar(
              spacing: 8.0,
              children: [
                AppFilterChip(
                  label: 'Все',
                  isSelected: currentFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                AppFilterChip(
                  label: 'Сырье для кухни',
                  icon: PhosphorIconsRegular.cookingPot,
                  isSelected: currentFilter == 'raw',
                  onTap: () => onFilterChanged('raw'),
                ),
                AppFilterChip(
                  label: 'Витрина',
                  icon: PhosphorIconsRegular.storefront,
                  isSelected: currentFilter == 'retail',
                  onTap: () => onFilterChanged('retail'),
                ),
                if (onSearchChanged != null)
                  AppSearchField(
                    controller: searchController,
                    mode: AppSearchMode.collapsible,
                    size: AppSearchFieldSize.sm,
                    hintText: 'Поиск остатков...',
                    onChanged: onSearchChanged,
                  ),
              ],
            ),
          ),
          AppExpandAllButton(
            isExpanded: isExpandedAll,
            onToggle: onToggleExpandAll,
            mode: AppExpandAllMode.full,
          ),
        ],
      ),
    );
  }
}
