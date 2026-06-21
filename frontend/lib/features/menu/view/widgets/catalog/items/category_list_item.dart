import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import '../catalog_icons.dart';
import '../catalog_enums.dart';

class CategoryListItem extends StatelessWidget {
  final dynamic category;
  final CategoryManageMode manageMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onVisibilityToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.manageMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelect,
    required this.onVisibilityToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Opacity(
          opacity: category.isVisible ? 1.0 : 0.5,
          child: buildCategoryIcon(category.name, size: 24, color: AppColors.brandPrimary),
        ),
        title: Opacity(
          opacity: category.isVisible ? 1.0 : 0.5,
          child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        trailing: manageMode == CategoryManageMode.delete
            ? Checkbox(value: isSelected, onChanged: onToggleSelect)
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  else if (val == 'visibility') onVisibilityToggle();
                  else if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  PopupMenuItem(value: 'visibility', child: Text(category.isVisible ? 'Скрыть на кассе' : 'Показать на кассе')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}
