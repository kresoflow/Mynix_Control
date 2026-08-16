import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'catalog_enums.dart';

class CatalogHeaderManageMode extends StatelessWidget {
  final CategoryManageMode manageMode;
  final bool isMobile;
  final int selectedCount;
  final bool isAllSelected;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAllToggle;
  final VoidCallback onDeleteSelected;

  const CatalogHeaderManageMode({
    super.key,
    required this.manageMode,
    required this.isMobile,
    required this.selectedCount,
    required this.isAllSelected,
    required this.onClearSelection,
    required this.onSelectAllToggle,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (manageMode == CategoryManageMode.delete) {
      if (isMobile) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выбрано: $selectedCount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x),
                  color: colorScheme.onErrorContainer,
                  onPressed: onClearSelection,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      isAllSelected ? PhosphorIconsRegular.square : PhosphorIconsRegular.checkSquare,
                      size: 18,
                    ),
                    label: Text(isAllSelected ? 'Снять' : 'Все'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onErrorContainer,
                      side: BorderSide(color: colorScheme.onErrorContainer),
                    ),
                    onPressed: onSelectAllToggle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(PhosphorIconsRegular.trash, size: 18),
                    label: const Text('Удалить'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: selectedCount > 0 ? onDeleteSelected : null,
                  ),
                ),
              ],
            ),
          ],
        );
      }

      return Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x),
            color: colorScheme.onErrorContainer,
            onPressed: onClearSelection,
          ),
          const SizedBox(width: 8),
          Text(
            'Выбрано: $selectedCount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            icon: Icon(
              isAllSelected ? PhosphorIconsRegular.square : PhosphorIconsRegular.checkSquare,
              size: 18,
            ),
            label: Text(isAllSelected ? 'Снять выделение' : 'Выбрать все'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onErrorContainer,
              side: BorderSide(color: colorScheme.onErrorContainer),
            ),
            onPressed: onSelectAllToggle,
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            icon: const Icon(PhosphorIconsRegular.trash, size: 18),
            label: const Text('Удалить выбранные'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: selectedCount > 0 ? onDeleteSelected : null,
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(PhosphorIconsRegular.x),
          onPressed: onClearSelection,
        ),
        const SizedBox(width: 8),
        const Text(
          'Режим видимости',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton(
          onPressed: onClearSelection,
          child: const Text('Готово'),
        ),
      ],
    );
  }
}
