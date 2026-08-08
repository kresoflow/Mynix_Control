import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import '../catalog_enums.dart';
import '../catalog_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    String? effectiveIcon = category.icon;
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      effectiveIcon = category.getInheritedIcon(catState.categories);
    }

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Opacity(
          opacity: category.isVisible ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: (effectiveIcon == null || effectiveIcon.isEmpty)
                ? Text(
                    category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  )
                : IconHelper.buildIcon(
                    effectiveIcon,
                    size: 24,
                    color: AppColors.brandPrimary,
                  ),
          ),
        ),
        title: Opacity(
          opacity: category.isVisible ? 1.0 : 0.5,
          child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        trailing: manageMode == CategoryManageMode.delete
            ? Checkbox(value: isSelected, onChanged: onToggleSelect)
            : PopupMenuButton<String>(
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'visibility') onVisibilityToggle();
                  else if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  PopupMenuItem(value: 'visibility', child: Text(category.isVisible ? 'Скрыть на кассе' : 'Показать на кассе')),
                  PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.danger))),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}
