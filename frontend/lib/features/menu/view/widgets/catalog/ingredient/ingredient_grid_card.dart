// ==============================================================================
// Title: IngredientGridCard
// Path: frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_grid_card.dart
// Description: Карточка сырья для сеточного отображения (IngredientGridView).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_deletion_dialogs.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/catalog_dialogs.dart';

// [UI-KIT] Плитка элемента сырья с контекстным меню и индикацией остатков
class IngredientGridCard extends StatelessWidget {
  final Ingredient item;
  final bool isSelected;
  final bool isManageMode;
  final String catName;
  final String? iconStr;
  final String currency;
  final Function(int id, bool selected) onToggleSelect;

  const IngredientGridCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isManageMode,
    required this.catName,
    required this.iconStr,
    required this.currency,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasIcon = iconStr != null && iconStr!.isNotEmpty;
    final isLow = item.isLowStock;
    final isCritical = item.currentStock <= 0;
    final stockColor = isCritical ? AppColors.danger : (isLow ? AppColors.warning : AppColors.success);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandPrimary.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: AppRadii.cardRadius,
          onTap: isManageMode
              ? () => onToggleSelect(item.id, !isSelected)
              : () => showAddIngredientDialog(context, itemToEdit: item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopRow(context, isDark),
                _buildCenterIcon(isDark, hasIcon, stockColor),
                _buildNameSection(isDark),
                _buildBottomRow(isDark, stockColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: AppRadii.badgeRadius,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                item.displayCode,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (item.isArchived)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: AppRadii.radiusXs,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  'Архив',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
          ],
        ),
        if (isManageMode)
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: (val) => onToggleSelect(item.id, val == true),
              activeColor: AppColors.brandPrimary,
            ),
          )
        else
          _buildActionMenu(context, isDark),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context, bool isDark) {
    return SizedBox(
      width: 24,
      height: 24,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          PhosphorIconsRegular.dotsThreeVertical,
          size: 16,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        onSelected: (val) {
          if (val == 'edit') {
            showAddIngredientDialog(context, itemToEdit: item);
          } else if (val == 'delete') {
            CatalogDeletionDialogs.confirmDeleteIngredient(context, item);
          } else if (val == 'restore') {
            context.read<IngredientBloc>().add(RestoreIngredient(item.id));
          }
        },
        itemBuilder: (ctx) => item.isArchived
            ? [
                _menuItem('restore', 'Восстановить', PhosphorIconsRegular.arrowCounterClockwise),
                _menuItem('delete', 'Удалить навсегда', PhosphorIconsRegular.trash, AppColors.danger),
              ]
            : [
                _menuItem('edit', 'Редактировать', PhosphorIconsRegular.pencilSimple),
                _menuItem('delete', 'Архивировать', PhosphorIconsRegular.archive, AppColors.danger),
              ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String val, String text, IconData icon, [Color? color]) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: color != null ? TextStyle(color: color) : null),
        ],
      ),
    );
  }

  Widget _buildCenterIcon(bool isDark, bool hasIcon, Color stockColor) {
    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: (hasIcon ? stockColor : AppColors.brandPrimary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: hasIcon
            ? IconHelper.buildIcon(
                iconStr,
                size: 22,
                color: stockColor,
              )
            : Text(
                item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
      ),
    );
  }

  Widget _buildNameSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: item.isArchived ? TextDecoration.lineThrough : null,
            color: item.isArchived
                ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                : (isDark ? AppColors.darkText : AppColors.lightText),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          catName,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomRow(bool isDark, Color stockColor) {
    final costStr = item.costPerUnit.toStringAsFixed(
      item.costPerUnit.truncateToDouble() == item.costPerUnit ? 0 : 2,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.12),
              borderRadius: AppRadii.badgeRadius,
            ),
            child: Text(
              UnitFormatter.formatAmount(item.currentStock, item.unit),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: stockColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$costStr $currency/${UnitFormatter.format(item.unit)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      ],
    );
  }
}
