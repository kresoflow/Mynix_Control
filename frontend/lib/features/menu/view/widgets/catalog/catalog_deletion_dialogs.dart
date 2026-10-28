// ==============================================================================
// МОДУЛЬ: Меню / Каталог / Стандартизированные диалоги удаления и архивации
// ДОМЕН: lib/features/menu/view/widgets/catalog/catalog_deletion_dialogs.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'dialogs/catalog_variation_deletion_modal.dart';

// ─── 1. Менеджер диалогов подтверждения удаления ─────────────────────────────
/// [UI-KIT] Набор стандартизированных диалогов удаления и архивации каталога
/// на базе компонента AppConfirmDialog.
class CatalogDeletionDialogs {
  /// Подтверждение мягкой архивации категории.
  static Future<void> confirmDeleteCategory(BuildContext context, dynamic category) async {
    if (category.isArchived == true) {
      return confirmHardDeleteCategory(context, category);
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Архивация категории',
      message: 'Переместить категорию «${category.name}» в архив?\n'
          'Все её позиции будут скрыты из кассы и активных списков, но сохранятся в архиве.',
      confirmLabel: 'Архивировать',
      confirmIcon: PhosphorIconsRegular.archive,
      isDanger: true,
      icon: PhosphorIconsRegular.archive,
    );

    if (confirmed == true && context.mounted) {
      context.read<CategoryBloc>().add(DeleteCategory(category.id, mode: 'soft'));
    }
  }

  /// Подтверждение безвозвратного удаления категории из БД.
  static Future<void> confirmHardDeleteCategory(BuildContext context, dynamic category) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Удаление навсегда',
      message: 'Окончательно стереть категорию «${category.name}» из базы данных?\n'
          'Это действие необратимо и возможно только если по её товарам нет истории продаж и склада.',
      confirmLabel: 'Удалить навсегда',
      confirmIcon: PhosphorIconsRegular.trash,
      isDanger: true,
      icon: PhosphorIconsRegular.trash,
    );

    if (confirmed == true && context.mounted) {
      context.read<CategoryBloc>().add(DeleteCategory(category.id, mode: 'hard'));
    }
  }

  /// Подтверждение мягкой архивации блюда или розничного товара.
  static Future<void> confirmDeleteItem(BuildContext context, dynamic item) async {
    if (!item.isAvailable) {
      return confirmHardDeleteItem(context, item);
    }

    if (item is MenuItem) {
      final hasVariations = (item.variationPrices != null && item.variationPrices!.isNotEmpty) ||
          (item.variationsSummary != null && item.variationsSummary!.isNotEmpty);
      if (hasVariations) {
        showVariationDeletionModal(context, item);
        return;
      }
    }

    final displayName = item.cleanName ?? item.name;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Архивация позиции',
      message: 'Переместить позицию «$displayName» в архив?\n'
          'Она исчезнет из кассы и накладных, но её всегда можно будет восстановить из архива.',
      confirmLabel: 'Архивировать',
      confirmIcon: PhosphorIconsRegular.archive,
      isDanger: true,
      icon: PhosphorIconsRegular.archive,
    );

    if (confirmed == true && context.mounted) {
      context.read<MenuBloc>().add(DeleteMenuItem(item.id, mode: 'soft'));
    }
  }

  /// Подтверждение безвозвратного удаления блюда/товара из БД.
  static Future<void> confirmHardDeleteItem(BuildContext context, dynamic item) async {
    final displayName = item.cleanName ?? item.name;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Удаление навсегда',
      message: 'Окончательно удалить позицию «$displayName» из базы данных?\n'
          'Это действие необратимо и возможно только если по ней нет истории продаж и склада.',
      confirmLabel: 'Удалить навсегда',
      confirmIcon: PhosphorIconsRegular.trash,
      isDanger: true,
      icon: PhosphorIconsRegular.trash,
    );

    if (confirmed == true && context.mounted) {
      context.read<MenuBloc>().add(DeleteMenuItem(item.id, mode: 'hard'));
    }
  }

  /// Подтверждение массового удаления или архивации выбранных элементов каталога.
  static Future<void> confirmDeleteSelected({
    required BuildContext context,
    required Set<int> selectedItems,
    required Set<int> selectedCategories,
    required VoidCallback onCleared,
    bool isArchived = false,
  }) async {
    final selectedCount = selectedItems.length + selectedCategories.length;
    if (selectedCount == 0) return;

    bool effectivelyArchived = isArchived;
    if (!effectivelyArchived) {
      final menuState = context.read<MenuBloc>().state;
      final catState = context.read<CategoryBloc>().state;
      final allItemsArchived = selectedItems.isEmpty ||
          (menuState is MenuLoaded &&
              selectedItems.every(
                (id) => menuState.items.any((i) => i.id == id && !i.isAvailable),
              ));
      final allCatsArchived = selectedCategories.isEmpty ||
          (catState is CategoryLoaded &&
              selectedCategories.every(
                (id) => catState.categories.any((c) => c.id == id && c.isArchived),
              ));
      if (allItemsArchived && allCatsArchived) {
        effectivelyArchived = true;
      }
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: effectivelyArchived ? 'Удаление навсегда' : 'Массовая архивация',
      message: effectivelyArchived
          ? 'Окончательно удалить выбранные элементы ($selectedCount шт.) из базы данных?\n'
              'Это действие необратимо и возможно только если по ним нет истории продаж и склада.'
          : 'Переместить выбранные элементы ($selectedCount шт.) в архив?\n'
              'Они будут скрыты из кассы, но сохранятся в архиве.',
      confirmLabel: effectivelyArchived ? 'Удалить навсегда' : 'Архивировать',
      confirmIcon: effectivelyArchived ? PhosphorIconsRegular.trash : PhosphorIconsRegular.archive,
      isDanger: true,
      icon: effectivelyArchived ? PhosphorIconsRegular.trash : PhosphorIconsRegular.archive,
    );

    if (confirmed == true && context.mounted) {
      final mode = effectivelyArchived ? 'hard' : 'soft';
      if (selectedItems.isNotEmpty) {
        context.read<MenuBloc>().add(
          DeleteMenuItemsBulk(selectedItems.toList(), mode: mode),
        );
      }
      if (selectedCategories.isNotEmpty) {
        context.read<CategoryBloc>().add(
          DeleteCategoriesBulk(selectedCategories.toList(), mode: mode),
        );
      }
      onCleared();
    }
  }

  /// Подтверждение мягкой архивации единицы сырья.
  static Future<void> confirmDeleteIngredient(BuildContext context, Ingredient item) async {
    if (item.isArchived) {
      return confirmHardDeleteIngredient(context, item);
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Архивация сырья',
      message: 'Архивировать позицию «${item.name}»?\n'
          'Она исчезнет из активных списков, но сохранится в истории движения склада.',
      confirmLabel: 'Архивировать',
      confirmIcon: PhosphorIconsRegular.archive,
      isDanger: true,
      icon: PhosphorIconsRegular.archive,
    );

    if (confirmed == true && context.mounted) {
      context.read<IngredientBloc>().add(DeleteIngredient(item.id, mode: 'soft'));
    }
  }

  /// Подтверждение безвозвратного удаления сырья из БД.
  static Future<void> confirmHardDeleteIngredient(BuildContext context, Ingredient item) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Удаление навсегда',
      message: 'Окончательно удалить позицию сырья «${item.name}» из базы данных?\n'
          'Это возможно только если по ней нет документов, проводок и связей с техкартами.',
      confirmLabel: 'Удалить навсегда',
      confirmIcon: PhosphorIconsRegular.trash,
      isDanger: true,
      icon: PhosphorIconsRegular.trash,
    );

    if (confirmed == true && context.mounted) {
      context.read<IngredientBloc>().add(DeleteIngredient(item.id, mode: 'hard'));
    }
  }
}
