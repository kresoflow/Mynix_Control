// ==============================================================================
// Title: IngredientHeaderBar (Catalog Toolbar)
// Path: frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_header_bar.dart
// Description: Тулбар и панель действий вкладки сырья и заготовок.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';

// [UI-KIT] Шапка каталога сырья с тулбаром и массовыми действиями
class IngredientHeaderBar extends StatelessWidget {
  final bool isManageMode;
  final bool isGridView;
  final bool showArchived;
  final int archivedCount;
  final Set<int> selectedIngredients;
  final int? selectedCategoryId;
  final VoidCallback onSelectAll;
  final VoidCallback onConfirmRestore;
  final VoidCallback onConfirmDelete;
  final VoidCallback onCancelManageMode;
  final ValueChanged<bool> onToggleGridView;
  final VoidCallback onToggleShowArchived;
  final VoidCallback onEnterManageMode;

  const IngredientHeaderBar({
    super.key,
    required this.isManageMode,
    required this.isGridView,
    required this.showArchived,
    required this.archivedCount,
    required this.selectedIngredients,
    required this.selectedCategoryId,
    required this.onSelectAll,
    required this.onConfirmRestore,
    required this.onConfirmDelete,
    required this.onCancelManageMode,
    required this.onToggleGridView,
    required this.onToggleShowArchived,
    required this.onEnterManageMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ingState = context.watch<IngredientBloc>().state;

    return LayoutBuilder(
      builder: (context, headerConstraints) {
        final isNarrow = headerConstraints.maxWidth < 750;
        final actionButtons = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isManageMode) ...[
                _buildManageControls(context, isDark, ingState),
              ] else ...[
                _buildDefaultControls(context),
              ],
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сырье и заготовки', style: AppTextStyles.h2),
              const SizedBox(height: 10),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Сырье и заготовки', style: AppTextStyles.h2),
            actionButtons,
          ],
        );
      },
    );
  }

  Widget _buildManageControls(BuildContext context, bool isDark, IngredientState ingState) {
    final raw = ingState is IngredientLoaded
        ? ingState.ingredients.where((i) => !i.isRetail && (showArchived ? i.isArchived : !i.isArchived)).toList()
        : [];
    final filtered = selectedCategoryId == null
        ? raw
        : raw.where((i) => i.categoryId == selectedCategoryId).toList();
    final isAllSelected = filtered.isNotEmpty && selectedIngredients.length == filtered.length;
    final IconData badgeIcon = selectedIngredients.isEmpty
        ? PhosphorIconsRegular.square
        : (isAllSelected ? PhosphorIconsRegular.checkSquare : PhosphorIconsRegular.minusSquare);
    final highlightColor = showArchived ? AppColors.brandPrimary : AppColors.danger;
    final isSelected = selectedIngredients.isNotEmpty;
    final Color badgeColor = isSelected ? highlightColor : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);
    final boxColor = isSelected ? highlightColor.withValues(alpha: isDark ? 0.2 : 0.1) : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final borderColor = isSelected ? highlightColor.withValues(alpha: 0.4) : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: boxColor, borderRadius: AppRadii.inputRadius, border: Border.all(color: borderColor)),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, size: 16, color: badgeColor),
              const SizedBox(width: 6),
              Text(
                'Выбрано: ${selectedIngredients.length}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? badgeColor : (isDark ? AppColors.darkText : AppColors.lightText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AppSecondaryButton(
          label: isAllSelected ? 'Снять выделение' : 'Выбрать все',
          icon: isAllSelected ? PhosphorIconsRegular.checkSquare : PhosphorIconsRegular.square,
          isSelected: isAllSelected,
          height: 38,
          size: AppButtonSize.md,
          onPressed: onSelectAll,
        ),
        const SizedBox(width: 8),
        if (showArchived) ...[
          AppPrimaryButton(
            label: 'Восстановить (${selectedIngredients.length})',
            icon: PhosphorIconsRegular.arrowCounterClockwise,
            height: 38,
            size: AppButtonSize.md,
            onPressed: selectedIngredients.isEmpty ? null : onConfirmRestore,
          ),
          const SizedBox(width: 8),
        ],
        AppDangerButton(
          label: showArchived ? 'Удалить навсегда (${selectedIngredients.length})' : 'Архивировать (${selectedIngredients.length})',
          icon: showArchived ? PhosphorIconsRegular.trash : PhosphorIconsRegular.archive,
          height: 38,
          size: AppButtonSize.md,
          onPressed: selectedIngredients.isEmpty ? null : onConfirmDelete,
        ),
        const SizedBox(width: 8),
        AppGhostButton(
          label: 'Отмена',
          icon: PhosphorIconsRegular.x,
          height: 38,
          size: AppButtonSize.md,
          onPressed: onCancelManageMode,
        ),
      ],
    );
  }

  Widget _buildDefaultControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSegmentedControl<bool>(
          size: AppSegmentedSize.md,
          selectedValue: isGridView,
          onValueChanged: onToggleGridView,
          items: const [
            AppSegmentedItem(
              value: true,
              icon: PhosphorIconsRegular.squaresFour,
              tooltip: 'Сетка',
            ),
            AppSegmentedItem(
              value: false,
              icon: PhosphorIconsRegular.listDashes,
              tooltip: 'Список',
            ),
          ],
        ),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: archivedCount > 0,
          label: Text('$archivedCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.brandPrimary,
          offset: const Offset(4, -4),
          child: AppSecondaryButton(
            label: '',
            icon: PhosphorIconsRegular.archive,
            tooltip: showArchived ? 'Скрыть архив' : (archivedCount > 0 ? 'Архив ($archivedCount)' : 'Архив'),
            isSelected: showArchived,
            height: 38,
            width: 38,
            size: AppButtonSize.md,
            onPressed: onToggleShowArchived,
          ),
        ),
        const SizedBox(width: 8),
        AppSecondaryButton(
          label: 'Выбрать',
          icon: PhosphorIconsRegular.checkSquareOffset,
          height: 38,
          size: AppButtonSize.md,
          onPressed: onEnterManageMode,
        ),
        const SizedBox(width: 10),
        AppMenuButton(
          label: 'Добавить',
          icon: PhosphorIconsRegular.plus,
          size: AppButtonSize.md,
          items: const [
            AppMenuItem(id: 'ingredient', label: 'Сырье / Ингредиент', icon: PhosphorIconsRegular.leaf),
            AppMenuItem(id: 'category', label: 'Категория сырья', icon: PhosphorIconsRegular.folderPlus),
            AppMenuDivider(),
            AppMenuItem(id: 'bulk_add', label: 'Массовый ввод', icon: PhosphorIconsRegular.table),
          ],
          onSelected: (val) {
            if (val == 'ingredient') {
              showAddIngredientDialog(context, initialCategoryId: selectedCategoryId);
            } else if (val == 'category') {
              showAddCategoryDialog(context, currentCategoryId: selectedCategoryId, type: 'ingredient');
            } else if (val == 'bulk_add') {
              showDialog(
                context: context,
                builder: (_) => BulkAddModal(initialTabIndex: 2, initialParentId: selectedCategoryId),
              );
            }
          },
        ),
      ],
    );
  }
}

// [UI-KIT] Информационный баннер режима архива сырья
class IngredientArchiveBanner extends StatelessWidget {
  final int archivedCount;
  final VoidCallback onClose;

  const IngredientArchiveBanner({
    super.key,
    required this.archivedCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.archive, size: 18, color: AppColors.brandPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Режим архива ($archivedCount поз.). Архивные позиции скрыты из кассы, накладных и расчетов остатков.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          AppGhostButton(
            label: 'Закрыть архив',
            icon: PhosphorIconsRegular.x,
            size: AppButtonSize.sm,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

