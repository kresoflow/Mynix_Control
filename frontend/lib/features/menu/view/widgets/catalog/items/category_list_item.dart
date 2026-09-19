import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/widgets/color_picker/color_picker_utils.dart';
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
    String? effectiveColor = category.color;
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      effectiveIcon = category.getInheritedIcon(catState.categories);
      effectiveColor = category.getInheritedColor(catState.categories);
    }

    final isArchived = category.isArchived;
    final isHiddenFromPos = !category.isVisible;
    final customColor = ColorPickerUtils.parseHex(effectiveColor);
    final accentColor = isArchived ? Colors.grey : (customColor ?? AppColors.brandPrimary);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Opacity(
          opacity: isArchived ? 0.45 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: (effectiveIcon == null || effectiveIcon.isEmpty)
                ? Text(
                    category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  )
                : IconHelper.buildIcon(
                    effectiveIcon,
                    size: 24,
                    color: accentColor,
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
              ] else if (isHiddenFromPos) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.eyeSlash, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('Скрыто на кассе', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontSize: 10)),
                    ],
                  ),
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
