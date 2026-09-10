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
    return Row(
      children: [
        // Filter chips (UI Kit)
        AppFilterBar(
          spacing: 6.0,
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
          ],
        ),

        const Spacer(),

        // Search bar on the right
        SizedBox(
          width: 280,
          child: AppSearchField(
            size: AppSearchFieldSize.md,
            hintText: 'Поиск по номеру, поставщику...',
            onChanged: onSearchChanged,
          ),
        ),
      ],
    );
  }
}
