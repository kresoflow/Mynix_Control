import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';

class CatalogDeletionDialogs {
  static void confirmDeleteCategory(BuildContext context, dynamic category) {
    if (category.isArchived == true) {
      confirmHardDeleteCategory(context, category);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Архивация категории',
        icon: PhosphorIconsRegular.archive,
        isDestructive: true,
        width: 420,
        content: Text(
          'Архивировать категорию «${category.name}»?\nВсе вложенные блюда и товары будут заархивированы и скрыты.',
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
      builder: (ctx) => AppDialog(
        title: 'Удаление навсегда',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Окончательно стереть категорию «${category.name}» из базы данных?\nЭто возможно только если по её товарам нет истории продаж.',
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
    if (!item.isAvailable) {
      confirmHardDeleteItem(context, item);
      return;
    }

    final displayName = item.cleanName ?? item.name;
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Архивация позиции',
        icon: PhosphorIconsRegular.archive,
        isDestructive: true,
        width: 420,
        content: Text(
          'Архивировать позицию «$displayName»?\nОна исчезнет с кассы, но сохранится в отчетах.',
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
              context.read<MenuBloc>().add(DeleteMenuItem(item.id, mode: 'soft'));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static void confirmHardDeleteItem(BuildContext context, dynamic item) {
    final displayName = item.cleanName ?? item.name;
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Удаление навсегда',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Окончательно удалить позицию «$displayName» из базы данных?\nЭто возможно только если по ней нет истории продаж.',
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
              context.read<MenuBloc>().add(DeleteMenuItem(item.id, mode: 'hard'));
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
      builder: (ctx) => AppDialog(
        title: 'Массовое удаление',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Удалить выбранные элементы ($selectedCount шт.)?\nВложенные позиции будут архивированы.',
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
              for (var itemId in selectedItems) {
                context.read<MenuBloc>().add(DeleteMenuItem(itemId, mode: 'soft'));
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

  static void confirmDeleteIngredient(BuildContext context, Ingredient item) {
    if (item.isArchived) {
      confirmHardDeleteIngredient(context, item);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Архивация сырья',
        icon: PhosphorIconsRegular.archive,
        isDestructive: true,
        width: 420,
        content: Text(
          'Архивировать позицию «${item.name}»?\nОна исчезнет из активных списков, но сохранится в истории движения склада.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppDangerButton(
            label: 'Архивировать',
            icon: PhosphorIconsRegular.archive,
            onPressed: () {
              context.read<IngredientBloc>().add(DeleteIngredient(item.id, mode: 'soft'));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static void confirmHardDeleteIngredient(BuildContext context, Ingredient item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Удаление навсегда',
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
        width: 420,
        content: Text(
          'Окончательно удалить позицию сырья «${item.name}» из базы данных?\nЭто возможно только если по ней нет документов, проводок и связей с техкартами.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        actions: [
          AppGhostButton(label: 'Отмена', onPressed: () => Navigator.pop(ctx)),
          AppDangerButton(
            label: 'Удалить навсегда',
            icon: PhosphorIconsRegular.trash,
            onPressed: () {
              context.read<IngredientBloc>().add(DeleteIngredient(item.id, mode: 'hard'));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
