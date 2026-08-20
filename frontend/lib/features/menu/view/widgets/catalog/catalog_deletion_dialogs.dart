import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';

class CatalogDeletionDialogs {
  static void confirmDeleteCategory(BuildContext context, dynamic category) {
    if (!category.isVisible) {
      confirmHardDeleteCategory(context, category);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Удаление категории',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Удалить категорию «${category.name}»?\nВсе вложенные блюда и товары будут заархивированы и скрыты.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppDangerButton(
            label: 'Удалить',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              context.read<CategoryBloc>().add(DeleteCategory(category.id, mode: 'all'));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static void confirmHardDeleteCategory(BuildContext context, dynamic category) {
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Удаление навсегда',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Окончательно стереть категорию «${category.name}» из базы данных?\nЭто возможно только если по её товарам не было продаж.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppDangerButton(
            label: 'Удалить навсегда',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              context.read<CategoryBloc>().add(DeleteCategory(category.id, mode: 'hard'));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static void confirmDeleteItem(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Архивация позиции',
        icon: PhosphorIconsRegular.archive,
        isDestructive: true,
        width: 420,
        content: Text(
          'Архивировать позицию «${item.name}»?\nОна исчезнет с кассы, но сохранится в отчетах.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppDangerButton(
            label: 'Архивировать',
            icon: PhosphorIconsRegular.archive,
            onPressed: () {
              context.read<MenuBloc>().add(DeleteMenuItem(item.id));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static void confirmDeleteSelected({
    required BuildContext context,
    required Set<int> selectedItems,
    required Set<int> selectedCategories,
    required VoidCallback onCleared,
  }) {
    final selectedCount = selectedItems.length + selectedCategories.length;
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
        title: 'Массовое удаление',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Удалить выбранные элементы ($selectedCount шт.)?\nВложенные позиции будут архивированы.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightSubtext),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppDangerButton(
            label: 'Удалить',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              for (var itemId in selectedItems) {
                context.read<MenuBloc>().add(DeleteMenuItem(itemId));
              }
              for (var catId in selectedCategories) {
                context.read<CategoryBloc>().add(DeleteCategory(catId, mode: 'all'));
              }
              Navigator.pop(ctx);
              onCleared();
            },
          ),
        ],
      ),
    );
  }
}
