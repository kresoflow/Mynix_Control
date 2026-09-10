import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/dialogs/create_ingredient_dialog.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';

class IngredientHeader extends StatelessWidget {
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final int? selectedCategoryId;
  final ValueChanged<bool> onManageModeChanged;
  final ValueChanged<Set<int>> onSelectedIngredientsChanged;
  final List<int> Function(List<dynamic>, int) getDescendantCategoryIds;
  final ValueChanged<String>? onSearchChanged;

  const IngredientHeader({
    super.key,
    required this.isManageMode,
    required this.selectedIngredients,
    required this.selectedCategoryId,
    required this.onManageModeChanged,
    required this.onSelectedIngredientsChanged,
    required this.getDescendantCategoryIds,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text('Управление сырьем', style: AppTextStyles.h3),
          const SizedBox(width: 12),
          if (onSearchChanged != null)
            AppSearchField(
              mode: AppSearchMode.collapsible,
              size: AppSearchFieldSize.md,
              hintText: 'Поиск по названию...',
              onChanged: onSearchChanged,
            ),
          const Spacer(),
          if (isManageMode) ...[
            AppGhostButton(
              size: AppButtonSize.md,
              onPressed: () {
                final state = context.read<IngredientBloc>().state;
                if (state is IngredientLoaded) {
                  final rawIngredients = state.ingredients.where((i) => !i.isRetail).toList();
                  final catState = context.read<CategoryBloc>().state;
                  List<int> allowedCategoryIds = [];
                  if (selectedCategoryId != null && catState is CategoryLoaded) {
                    allowedCategoryIds = getDescendantCategoryIds(catState.categories, selectedCategoryId!);
                  }

                  final filteredIngredients = selectedCategoryId == null
                      ? rawIngredients
                      : rawIngredients.where((i) => allowedCategoryIds.contains(i.categoryId)).toList();
                  
                  onSelectedIngredientsChanged(filteredIngredients.map((i) => i.id).toSet());
                }
              },
              icon: PhosphorIconsRegular.checkSquareOffset,
              label: 'Выбрать все',
            ),
            const SizedBox(width: 8),
            AppDangerButton(
              size: AppButtonSize.md,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Массовое удаление'),
                    content: Text('Удалить выбранные элементы (${selectedIngredients.length} шт.)?'),
                    actions: [
                      AppGhostButton(
                        size: AppButtonSize.md,
                        onPressed: () => Navigator.pop(ctx),
                        label: 'Отмена',
                      ),
                      AppDangerButton(
                        size: AppButtonSize.md,
                        onPressed: () {
                          for (var itemId in selectedIngredients) {
                            context.read<IngredientBloc>().add(DeleteIngredient(itemId));
                          }
                          onSelectedIngredientsChanged({});
                          onManageModeChanged(false);
                          Navigator.pop(ctx);
                        },
                        label: 'Удалить',
                      ),
                    ],
                  ),
                );
              },
              icon: PhosphorIconsRegular.trash,
              label: 'Удалить (${selectedIngredients.length})',
            ),
            const SizedBox(width: 8),
            AppGhostButton(
              size: AppButtonSize.md,
              onPressed: () {
                onManageModeChanged(false);
                onSelectedIngredientsChanged({});
              },
              label: 'Отмена',
            ),
          ] else ...[
            AppSecondaryButton(
              size: AppButtonSize.md,
              onPressed: () => onManageModeChanged(true),
              icon: PhosphorIconsRegular.pencilSimple,
              label: 'Управление',
            ),
            const SizedBox(width: 8),
            AppSecondaryButton(
              size: AppButtonSize.md,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const BulkAddModal(initialTabIndex: 2),
                );
              },
              icon: PhosphorIconsRegular.listPlus,
              label: 'Массово',
            ),
            const SizedBox(width: 8),
            AppPrimaryButton(
              size: AppButtonSize.md,
              onPressed: () {
                showAddIngredientDialog(context, initialCategoryId: selectedCategoryId);
              },
              icon: PhosphorIconsRegular.plus,
              label: 'Добавить',
            ),
          ],
        ],
      ),
    );
  }
}
