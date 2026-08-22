import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';

class IngredientHeaderBar extends StatelessWidget {
  final bool isManageMode;
  final bool isGridView;
  final Set<int> selectedIngredients;
  final int? selectedCategoryId;
  final VoidCallback onToggleManageMode;
  final VoidCallback onCancelManageMode;
  final ValueChanged<bool> onToggleView;
  final VoidCallback onSelectAll;
  final VoidCallback onDeleteSelected;
  final ValueChanged<String>? onSearchChanged;

  const IngredientHeaderBar({
    super.key,
    required this.isManageMode,
    this.isGridView = false,
    required this.selectedIngredients,
    required this.selectedCategoryId,
    required this.onToggleManageMode,
    required this.onCancelManageMode,
    required this.onToggleView,
    required this.onSelectAll,
    required this.onDeleteSelected,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Сырье и заготовки',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
          if (onSearchChanged != null)
            SizedBox(
              width: 240,
              child: AppTextField(
                hintText: 'Поиск по названию...',
                isCompact: true,
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 16),
                onChanged: onSearchChanged,
              ),
            ),
          const Spacer(),

          if (isManageMode) ...[
            AppGhostButton(
              label: 'Выбрать все',
              icon: PhosphorIconsRegular.checkSquareOffset,
              height: 36,
              onPressed: onSelectAll,
            ),
            const SizedBox(width: 8),
            AppDangerButton(
              label: 'Удалить (${selectedIngredients.length})',
              icon: PhosphorIconsRegular.trash,
              height: 36,
              onPressed: selectedIngredients.isEmpty ? null : onDeleteSelected,
            ),
            const SizedBox(width: 8),
            AppGhostButton(
              label: 'Отмена',
              height: 36,
              onPressed: onCancelManageMode,
            ),
          ] else ...[
            // View Switcher (Grid / List)
            Container(
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  _buildViewBtn(
                    isActive: !isGridView,
                    icon: PhosphorIconsRegular.list,
                    tooltip: 'Список',
                    onTap: () => onToggleView(false),
                    isDark: isDark,
                  ),
                  _buildViewBtn(
                    isActive: isGridView,
                    icon: PhosphorIconsRegular.squaresFour,
                    tooltip: 'Сетка',
                    onTap: () => onToggleView(true),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions Popover Menu (...)
            PopupMenuButton<String>(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Icon(
                  PhosphorIconsRegular.dotsThreeVertical,
                  size: 18,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              tooltip: 'Действия',
              onSelected: (val) {
                if (val == 'bulk') {
                  showDialog(
                    context: context,
                    builder: (_) => const BulkAddModal(initialTabIndex: 2),
                  );
                } else if (val == 'manage') {
                  onToggleManageMode();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'bulk',
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.listPlus, size: 16),
                      SizedBox(width: 10),
                      Text('Массовое добавление'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'manage',
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                      SizedBox(width: 10),
                      Text('Режим управления'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Main CTA Button
            AppPrimaryButton(
              label: 'Добавить',
              icon: PhosphorIconsRegular.plus,
              height: 36,
              onPressed: () {
                showAddIngredientDialog(context, initialCategoryId: selectedCategoryId);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewBtn({
    required bool isActive,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ),
      ),
    );
  }
}
