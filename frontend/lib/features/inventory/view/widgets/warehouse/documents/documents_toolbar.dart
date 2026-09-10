import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

class DocumentsToolbar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const DocumentsToolbar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterBar(
      spacing: 8.0,
      children: [
        AppFilterChip(
          label: 'Все',
          isSelected: selectedFilter == 'all',
          onTap: () => onFilterChanged('all'),
        ),
        AppFilterChip(
          label: 'Приходы',
          isSelected: selectedFilter == 'receipt',
          onTap: () => onFilterChanged('receipt'),
        ),
        AppFilterChip(
          label: 'Списания',
          isSelected: selectedFilter == 'write_off',
          onTap: () => onFilterChanged('write_off'),
        ),
        AppFilterChip(
          label: 'Инвентаризации',
          isSelected: selectedFilter == 'inventory',
          onTap: () => onFilterChanged('inventory'),
        ),
        AppSearchField(
          mode: AppSearchMode.collapsible,
          size: AppSearchFieldSize.sm,
          hintText: 'Поиск по номеру, поставщику...',
          shortcutHint: 'Ctrl+F',
          onChanged: onSearchChanged,
        ),
      ],
    );
  }
}
