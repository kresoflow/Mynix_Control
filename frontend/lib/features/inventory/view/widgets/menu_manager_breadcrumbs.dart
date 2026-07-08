import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/pos/models/menu_category.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class MenuManagerBreadcrumbs extends StatelessWidget {
  final List<MenuCategory> navigationHistory;
  final VoidCallback onNavigateRoot;
  final Function(int) onNavigateUpTo;
  final VoidCallback onAddCategory;
  final VoidCallback? onAddMenuItem;

  const MenuManagerBreadcrumbs({
    super.key,
    required this.navigationHistory,
    required this.onNavigateRoot,
    required this.onNavigateUpTo,
    required this.onAddCategory,
    this.onAddMenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onNavigateRoot,
            child: const Row(
              children: [
                Icon(PhosphorIconsRegular.house, size: 20),
                SizedBox(width: 8),
                Text('Главная', style: AppTextStyles.bodyLargeBold),
              ],
            ),
          ),
          ...List.generate(navigationHistory.length, (index) {
            final cat = navigationHistory[index];
            return Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    PhosphorIconsRegular.caretRight,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
                InkWell(
                  onTap: () => onNavigateUpTo(index),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight: index == navigationHistory.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: index == navigationHistory.length - 1
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ],
            );
          }),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAddCategory,
            icon: const Icon(PhosphorIconsRegular.folderPlus),
            label: const Text('Папка'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onAddMenuItem,
            icon: const Icon(PhosphorIconsRegular.plusSquare),
            label: const Text('Товар'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
