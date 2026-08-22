import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add_modal.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';

class IngredientHeaderBar extends StatelessWidget {
  final bool isManageMode;
  final bool isGridView;
  final List<Ingredient> ingredients;
  final Set<int> selectedIngredients;
  final int? selectedCategoryId;
  final VoidCallback onToggleManageMode;
  final VoidCallback onCancelManageMode;
  final ValueChanged<bool> onToggleView;
  final VoidCallback onSelectAll;
  final VoidCallback onDeleteSelected;

  const IngredientHeaderBar({
    super.key,
    required this.isManageMode,
    this.isGridView = false,
    required this.ingredients,
    required this.selectedIngredients,
    required this.selectedCategoryId,
    required this.onToggleManageMode,
    required this.onCancelManageMode,
    required this.onToggleView,
    required this.onSelectAll,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = ingredients.where((i) => !i.isRetail).toList();

    final int totalCount = raw.length;
    int alertCount = 0;
    double totalCost = 0.0;

    for (final item in raw) {
      if (item.isLowStock || item.currentStock <= item.minStockAlert) {
        alertCount++;
      }
      if (item.currentStock > 0) {
        totalCost += (item.currentStock * item.costPerUnit);
      }
    }

    return Container(
      height: 56,
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
          // Title
          Text(
            'Сырье и заготовки',
            style: AppTextStyles.h3.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),

          // ── 3 Center KPI Badges ─────────────────────────────────────
          _buildKpiChip(
            icon: PhosphorIconsRegular.package,
            iconColor: AppColors.brandPrimary,
            label: '$totalCount поз. сырья',
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildKpiChip(
            icon: alertCount > 0 ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
            iconColor: alertCount > 0 ? AppColors.danger : AppColors.success,
            label: alertCount > 0 ? '$alertCount на исходе' : 'Запасы в норме',
            isHighlighted: alertCount > 0,
            highlightColor: AppColors.danger,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildKpiChip(
            icon: PhosphorIconsRegular.coins,
            iconColor: AppColors.success,
            label: 'На складе: ${totalCost.toCurrency(context)}',
            isDark: isDark,
          ),

          const Spacer(),

          // Right Controls / Actions
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

            // Actions Menu (...)
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

  Widget _buildKpiChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    bool isHighlighted = false,
    Color? highlightColor,
    required bool isDark,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (highlightColor ?? AppColors.danger).withValues(alpha: 0.12)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlighted
              ? (highlightColor ?? AppColors.danger).withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlighted
                  ? (highlightColor ?? AppColors.danger)
                  : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
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
