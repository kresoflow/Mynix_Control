import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/widgets/app_card.dart';
import 'package:kreso_frontend/core/widgets/color_picker/color_picker_utils.dart';
import '../catalog_enums.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CategoryGridItem extends StatelessWidget {
  final dynamic category;
  final CategoryManageMode manageMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onVisibilityToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  const CategoryGridItem({
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArchived = category.isArchived;
    final isHiddenFromPos = !category.isVisible;
    final customColor = ColorPickerUtils.parseHex(effectiveColor);
    final accentColor = isArchived ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext) : (customColor ?? AppColors.brandPrimary);

    return AppCard(
        onTap: onTap,
        isSelected: isSelected,
        child: Stack(
        children: [
          Opacity(
            opacity: isArchived ? 0.45 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: (effectiveIcon == null || effectiveIcon.isEmpty)
                        ? Text(
                            category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                            style: AppTextStyles.h2.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : IconHelper.buildIcon(
                            effectiveIcon,
                            size: 32,
                            color: accentColor,
                          ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    category.name,
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      decoration: isArchived ? TextDecoration.lineThrough : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isArchived) ...[
                    const SizedBox(height: 4),
                    Text(
                      'В архиве',
                      style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (isHiddenFromPos) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsRegular.eyeSlash, size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          'Скрыто на кассе',
                          style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (manageMode == CategoryManageMode.delete)
            Positioned(top: 4, right: 4, child: Checkbox(value: isSelected, onChanged: onToggleSelect))
          else if (manageMode == CategoryManageMode.visibility)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(category.isVisible ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash, color: category.isVisible ? AppColors.success : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                tooltip: category.isVisible ? 'Отображается на кассе' : 'Скрыто на кассе',
                onPressed: onVisibilityToggle,
              ),
            )
          else if (manageMode == CategoryManageMode.none)
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: Icon(PhosphorIconsRegular.dotsThreeVertical, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
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
            ),
        ],
      ),
    );
  }
}
