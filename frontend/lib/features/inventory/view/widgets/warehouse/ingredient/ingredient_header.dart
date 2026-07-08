import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/dialogs/create_ingredient_dialog.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class IngredientHeader extends StatelessWidget {
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final int? selectedCategoryId;
  final ValueChanged<bool> onManageModeChanged;
  final ValueChanged<Set<int>> onSelectedIngredientsChanged;
  final List<int> Function(List<dynamic>, int) getDescendantCategoryIds;

  const IngredientHeader({
    super.key,
    required this.isManageMode,
    required this.selectedIngredients,
    required this.selectedCategoryId,
    required this.onManageModeChanged,
    required this.onSelectedIngredientsChanged,
    required this.getDescendantCategoryIds,
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
          const Spacer(),
          if (isManageMode) ...[
            TextButton.icon(
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
              icon: const Icon(PhosphorIconsRegular.checkSquareOffset),
              label: const Text('Выбрать все'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Массовое удаление'),
                    content: Text('Удалить выбранные элементы (${selectedIngredients.length} шт.)?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () {
                          for (var itemId in selectedIngredients) {
                            context.read<IngredientBloc>().add(DeleteIngredient(itemId));
                          }
                          onSelectedIngredientsChanged({});
                          onManageModeChanged(false);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Удалить'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(PhosphorIconsRegular.trash),
              label: Text('Удалить (${selectedIngredients.length})'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                onManageModeChanged(false);
                onSelectedIngredientsChanged({});
              },
              child: const Text('Отмена'),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => onManageModeChanged(true),
              icon: const Icon(PhosphorIconsRegular.pencilSimple),
              label: const Text('Управление'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const BulkAddModal(initialTabIndex: 2),
                );
              },
              icon: const Icon(PhosphorIconsRegular.listPlus),
              label: const Text('Массово'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                showAddIngredientDialog(context, initialCategoryId: selectedCategoryId);
              },
              icon: const Icon(PhosphorIconsRegular.plus),
              label: const Text('Добавить'),
            ),
          ],
        ],
      ),
    );
  }
}
