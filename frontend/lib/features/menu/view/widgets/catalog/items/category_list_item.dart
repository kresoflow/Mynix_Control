import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import '../catalog_enums.dart';
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
  final VoidCallback? onRestore;

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
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveIcon = category.icon;
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      effectiveIcon = category.getInheritedIcon(catState.categories);
    }

    final isArchived = !category.isVisible;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Opacity(
          opacity: isArchived ? 0.45 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isArchived ? Colors.grey : AppColors.brandPrimary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: (effectiveIcon == null || effectiveIcon.isEmpty)
                ? Text(
                    category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isArchived ? Colors.grey : AppColors.brandPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  )
                : IconHelper.buildIcon(
                    effectiveIcon,
                    size: 24,
                    color: isArchived ? Colors.grey : AppColors.brandPrimary,
                  ),
          ),
        ),
        title: Opacity(
          opacity: isArchived ? 0.45 : 1.0,
          child: Row(
            children: [
              Text(
                category.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: isArchived ? TextDecoration.lineThrough : null,
                ),
              ),
              if (isArchived) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('В архиве', style: AppTextStyles.caption.copyWith(color: Colors.grey, fontSize: 10)),
                ),
              ],
            ],
          ),
        ),
        trailing: manageMode == CategoryManageMode.delete
            ? Checkbox(value: isSelected, onChanged: onToggleSelect)
            : PopupMenuButton<String>(
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'visibility') {
                    onVisibilityToggle();
                  } else if (val == 'restore') {
                    if (onRestore != null) onRestore!();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => isArchived
                    ? [
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 18, color: AppColors.success),
                              SizedBox(width: 8),
                              Text('Восстановить'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
                              SizedBox(width: 8),
                              Text('Удалить навсегда', style: TextStyle(color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ]
                    : [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                              SizedBox(width: 8),
                              Text('Редактировать'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'visibility',
                          child: Row(
                            children: [
                              Icon(category.isVisible ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye, size: 18),
                              const SizedBox(width: 8),
                              Text(category.isVisible ? 'Скрыть на кассе' : 'Показать на кассе'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
                              SizedBox(width: 8),
                              Text('Удалить', style: TextStyle(color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ],
              ),
        onTap: onTap,
      ),
    );
  }
}
