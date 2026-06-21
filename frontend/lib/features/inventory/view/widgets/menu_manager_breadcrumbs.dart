import 'package:flutter/material.dart';
import 'package:retail_os_frontend/features/pos/models/menu_category.dart';

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
                Icon(Icons.home, size: 20),
                SizedBox(width: 8),
                Text('Главная', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Icons.chevron_right,
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
            icon: const Icon(Icons.create_new_folder),
            label: const Text('Папка'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onAddMenuItem,
            icon: const Icon(Icons.add_box),
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
