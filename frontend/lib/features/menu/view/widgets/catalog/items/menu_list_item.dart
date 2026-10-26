import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import '../catalog_enums.dart';
import '../catalog_deletion_dialogs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/color_picker/color_picker_utils.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_status_badge.dart';

class MenuListItem extends StatelessWidget {
  final MenuItem item;
  final CategoryManageMode manageMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const MenuListItem({
    super.key,
    required this.item,
    required this.manageMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    Color? inheritedColor;
    String? effectiveIcon = item.icon;
    
    // 1. Быстрая проверка иконки за O(1)
    if (effectiveIcon != null && effectiveIcon.isNotEmpty && !IconHelper.hasIcon(effectiveIcon)) {
      effectiveIcon = null;
    }
    
    // 2. Мгновенный поиск категории по хэш-таблице O(1)
    try {
      final categoryState = context.read<CategoryBloc>().state;
      if (categoryState is CategoryLoaded) {
        final category = categoryState.getById(item.categoryId);
        if (category != null) {
          if (effectiveIcon == null || effectiveIcon.isEmpty) {
            effectiveIcon = category.getInheritedIcon(categoryState.categories);
          }
          final colorHex = category.getInheritedColor(categoryState.categories);
          inheritedColor = ColorPickerUtils.parseHex(colorHex);
        }
      }
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = !item.isAvailable
        ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
        : (inheritedColor ?? AppColors.brandPrimary);

    Widget? finalIconWidget;
    if (effectiveIcon != null && effectiveIcon.isNotEmpty) {
      finalIconWidget = IconHelper.buildIcon(
        effectiveIcon,
        size: 20,
        color: accentColor,
      );
    }

    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.5,
      child: Material(
        color: AppColors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: finalIconWidget != null ? Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: finalIconWidget,
          ) : null,
          title: Text(item.cleanName, style: const TextStyle(fontSize: 16)),
          subtitle: (item.flavorString != null || item.variationsSummary != null || item.attributesString != null)
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.flavorString != null)
                        AppStatusBadge(
                          label: item.flavorString!,
                          variant: AppBadgeVariant.warning,
                          height: 20,
                        ),
                      if (item.variationsSummary != null)
                        AppStatusBadge(
                          label: item.variationsSummary!,
                          variant: AppBadgeVariant.info,
                          height: 20,
                        ),
                      if (item.flavorString == null && item.variationsSummary == null && item.attributesString != null)
                        AppStatusBadge(
                          label: item.attributesString!,
                          variant: AppBadgeVariant.neutral,
                          height: 20,
                        ),
                    ],
                  ),
                )
              : null,
          trailing: manageMode == CategoryManageMode.delete
              ? Checkbox(value: isSelected, onChanged: onToggleSelect)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      () {
                        if (item.variationPrices != null && item.variationPrices!.isNotEmpty) {
                          final prices = item.variationPrices!.cast<num>();
                          if (prices.length > 3) {
                            final minPrice = prices.reduce((num a, num b) => a < b ? a : b);
                            final maxPrice = prices.reduce((num a, num b) => a > b ? a : b);
                            return '${minPrice.toCurrency(context)} — ${maxPrice.toCurrency(context)}';
                          }
                          return prices.map((p) => p.toCurrency(context)).join('  ');
                        }
                        return item.price.toCurrency(context);
                      }(),
                      style: AppTextStyles.cardPrice,
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(PhosphorIconsRegular.dotsThreeVertical, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                      onSelected: (val) {
                        if (val == 'edit') {
                          onEdit();
                        } else if (val == 'delete') {
                          onDelete();
                        } else if (val == 'restore') {
                          onRestore();
                        } else if (val == 'hard_delete') {
                          CatalogDeletionDialogs.confirmHardDeleteItem(context, item);
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (item.isAvailable) const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                        if (item.isAvailable) const PopupMenuItem(value: 'delete', child: Text('В архив', style: TextStyle(color: AppColors.danger))),
                        if (!item.isAvailable) const PopupMenuItem(value: 'restore', child: Text('Восстановить', style: TextStyle(color: AppColors.success))),
                        if (!item.isAvailable) const PopupMenuItem(value: 'hard_delete', child: Text('Удалить навсегда', style: TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  ],
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
