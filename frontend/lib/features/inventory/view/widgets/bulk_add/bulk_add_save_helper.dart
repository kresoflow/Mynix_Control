import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'dish_row.dart';
import 'ingredient_row.dart';
import 'retail_row.dart';
import 'category_row.dart';
import 'bulk_add_payload_builder.dart';
import 'bulk_add_duplicate_validator.dart';

Future<void> performBulkSave({
  required BuildContext context,
  required int tabIndex,
  required int? targetCategoryId,
  required List<DishRowData> dishRows,
  required List<IngredientRowData> ingredientRows,
  required List<RetailRowData> retailRows,
  required List<CategoryRowData> categoryRows,
  String globalCategoryType = 'dish',
}) async {
  // ─── Валидация дубликатов перед сохранением ────────────────────────────────
  final duplicateErrors = <String>[];
  int totalRows = 0;
  if (tabIndex == 0) {
    totalRows = dishRows.length;
  } else if (tabIndex == 1) {
    totalRows = retailRows.length;
  } else if (tabIndex == 2) {
    totalRows = ingredientRows.length;
  } else if (tabIndex == 3) {
    totalRows = categoryRows.length;
  }

  for (int i = 0; i < totalRows; i++) {
    final dup = BulkAddDuplicateValidator.checkDuplicate(
      context: context,
      tabIndex: tabIndex,
      index: i,
      dishRows: dishRows,
      retailRows: retailRows,
      ingredientRows: ingredientRows,
      categoryRows: categoryRows,
      categoryType: globalCategoryType,
    );
    if (dup != null) {
      duplicateErrors.add('Строка ${i + 1}: $dup');
    }
  }

  if (duplicateErrors.isNotEmpty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Обнаружены дубликаты',
        icon: PhosphorIconsRegular.warningCircle,
        width: 480,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Введенные строки содержат повторы или уже существуют в каталоге (${duplicateErrors.length} шт.):',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: AppRadii.cardRadius,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: duplicateErrors.map((err) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(PhosphorIconsRegular.warning, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(child: Text(err, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Рекомендуется отменить сохранение и удалить или исправить повторяющиеся позиции.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ],
        ),
        actions: [
          AppGhostButton(
            label: 'Исправить строки',
            size: AppButtonSize.md,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          const SizedBox(width: 8),
          AppDangerButton(
            label: 'Всё равно сохранить',
            size: AppButtonSize.md,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (proceed != true || !context.mounted) return;
  }

  // Предупреждение при сохранении без категории (кроме вкладки папок)
  if (targetCategoryId == null && tabIndex != 3) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.folderOpen,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Без категории', style: AppTextStyles.h3),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Позиции будут добавлены в корень каталога без папки.\n'
                'Найти их можно в разделе «Без категории».',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkText.withValues(alpha: 0.6)
                      : AppColors.lightText.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppGhostButton(
                    label: 'Отмена',
                    size: AppButtonSize.md,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  const SizedBox(width: 8),
                  AppPrimaryButton(
                    label: 'Продолжить',
                    size: AppButtonSize.md,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  if (tabIndex == 3) {
    final bulkData = buildCategoryPayload(
      categoryRows: categoryRows,
      targetCategoryId: targetCategoryId,
      globalCategoryType: globalCategoryType,
    );
    if (bulkData.isNotEmpty) {
      context.read<CategoryBloc>().add(CreateCategoriesBulk(categories: bulkData));
    }
  } else if (tabIndex == 0) {
    final items = buildDishPayload(
      dishRows: dishRows,
      targetCategoryId: targetCategoryId,
    );
    if (items.isNotEmpty) {
      context.read<MenuBloc>().add(CreateMenuItemsBulk(items: items));
    }
  } else if (tabIndex == 2) {
    final catState = context.read<CategoryBloc>().state;
    final ingState = context.read<IngredientBloc>().state;
    final ingredientCategories = catState is CategoryLoaded
        ? catState.categories.where((c) => c.categoryType == 'ingredient' && !c.isArchived).toList()
        : <MenuCategory>[];
    final existingIngredients = ingState is IngredientLoaded
        ? ingState.ingredients
        : <Ingredient>[];

    final items = buildIngredientPayload(
      ingredientRows: ingredientRows,
      targetCategoryId: targetCategoryId,
      ingredientCategories: ingredientCategories,
      existingIngredients: existingIngredients,
    );
    if (items.isNotEmpty) {
      context.read<IngredientBloc>().add(CreateIngredientsBulk(ingredients: items));
    }
  } else {
    final items = buildRetailPayload(
      retailRows: retailRows,
      targetCategoryId: targetCategoryId,
    );
    if (items.isNotEmpty) {
      context.read<MenuBloc>().add(CreateRetailProductsBulk(items: items));
    }
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Массовое добавление выполнено успешно!')),
  );
  Navigator.pop(context);
}

