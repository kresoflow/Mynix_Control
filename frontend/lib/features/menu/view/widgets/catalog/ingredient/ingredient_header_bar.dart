import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';

class IngredientHeaderBar extends StatelessWidget {
  final bool isManageMode;
  final Set<int> selectedIngredients;
  final int? selectedCategoryId;
  final VoidCallback onToggleManageMode;
  final VoidCallback onCancelManageMode;
  final VoidCallback onSelectAll;
  final VoidCallback onDeleteSelected;

  const IngredientHeaderBar({
    super.key,
    required this.isManageMode,
    required this.selectedIngredients,
    required this.selectedCategoryId,
    required this.onToggleManageMode,
    required this.onCancelManageMode,
    required this.onSelectAll,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Text('Управление сырьем', style: AppTextStyles.h3),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isManageMode) ...[
                    AppGhostButton(
                      label: 'Выбрать все',
                      icon: PhosphorIconsRegular.checkSquareOffset,
                      height: 38,
                      onPressed: onSelectAll,
                    ),
                    const SizedBox(width: 8),
                    AppDangerButton(
                      label: 'Удалить (${selectedIngredients.length})',
                      icon: PhosphorIconsRegular.trash,
                      height: 38,
                      onPressed: selectedIngredients.isEmpty ? null : onDeleteSelected,
                    ),
                    const SizedBox(width: 8),
                    AppGhostButton(
                      label: 'Отмена',
                      height: 38,
                      onPressed: onCancelManageMode,
                    ),
                  ] else ...[
                    AppSecondaryButton(
                      label: 'Управление',
                      icon: PhosphorIconsRegular.pencilSimple,
                      height: 38,
                      onPressed: onToggleManageMode,
                    ),
                    const SizedBox(width: 8),
                    AppSecondaryButton(
                      label: 'Массово',
                      icon: PhosphorIconsRegular.listPlus,
                      height: 38,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const BulkAddModal(initialTabIndex: 2),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    AppPrimaryButton(
                      label: 'Добавить',
                      icon: PhosphorIconsRegular.plus,
                      height: 38,
                      onPressed: () {
                        showAddIngredientDialog(context, initialCategoryId: selectedCategoryId);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
