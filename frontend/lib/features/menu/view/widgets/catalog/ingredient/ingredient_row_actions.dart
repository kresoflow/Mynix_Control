// ==============================================================================
// МОДУЛЬ: Справочник / Действия строки сырья (Ingredient Row Actions)
// ДОМЕН: lib/features/menu/view/widgets/catalog/ingredient/ingredient_row_actions.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

/// [UI-KIT] Блок кнопок действий для строки сырья (Восстановить, Меню редактирования/удаления)
class IngredientRowActions extends StatelessWidget {
  final Ingredient item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  const IngredientRowActions({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.isArchived) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'Восстановить из архива',
            child: InkWell(
              onTap: () {
                if (onRestore != null) {
                  onRestore!();
                } else {
                  context.read<IngredientBloc>().add(RestoreIngredient(item.id));
                }
              },
              borderRadius: AppRadii.badgeRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: AppRadii.badgeRadius,
                  border: Border.all(
                    color: AppColors.brandPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 12, color: AppColors.brandPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'Восстановить',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          icon: Icon(
            PhosphorIconsRegular.dotsThreeVertical,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            size: 18,
          ),
          onSelected: (val) {
            if (val == 'edit') onEdit();
            if (val == 'delete') onDelete();
            if (val == 'restore') {
              if (onRestore != null) {
                onRestore!();
              } else {
                context.read<IngredientBloc>().add(RestoreIngredient(item.id));
              }
            }
          },
          itemBuilder: (ctx) => item.isArchived
              ? [
                  _menuItem('restore', PhosphorIconsRegular.arrowCounterClockwise, 'Восстановить'),
                  _menuItem('delete', PhosphorIconsRegular.trash, 'Удалить навсегда', color: AppColors.danger),
                ]
              : [
                  _menuItem('edit', PhosphorIconsRegular.pencilSimple, 'Редактировать'),
                  _menuItem('delete', PhosphorIconsRegular.archive, 'Архивировать', color: AppColors.danger),
                ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: color != null ? TextStyle(color: color) : null),
        ],
      ),
    );
  }
}
