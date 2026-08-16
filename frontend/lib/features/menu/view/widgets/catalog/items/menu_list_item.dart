import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import '../catalog_enums.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

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
    String? effectiveIcon = item.icon;
    
    // Check if the item's own icon is valid
    if (effectiveIcon != null && effectiveIcon.isNotEmpty) {
      final cleanName = effectiveIcon.startsWith('icon:') ? effectiveIcon.substring(5) : effectiveIcon;
      if (!IconHelper.availableIcons.contains(cleanName)) {
        effectiveIcon = null; // Invalid icon, fall back to parent
      }
    }
    
    try {
      final categoryState = context.read<CategoryBloc>().state;
      if (categoryState is CategoryLoaded) {
        final category = categoryState.categories.firstWhere((c) => c.id.toString() == item.categoryId);
        if (effectiveIcon == null || effectiveIcon.isEmpty) {
          effectiveIcon = category.getInheritedIcon(categoryState.categories);
        }
      }
    } catch (_) {}

    Widget? finalIconWidget;
    if (effectiveIcon != null && effectiveIcon.isNotEmpty) {
      finalIconWidget = IconHelper.buildIcon(
        effectiveIcon,
        size: 20,
        color: item.isAvailable ? AppColors.brandPrimary : Colors.grey,
      );
    }

    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: finalIconWidget != null ? Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (item.isAvailable ? AppColors.brandPrimary : Colors.grey).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: finalIconWidget,
          ) : null,
          title: Text(item.cleanName, style: const TextStyle(fontSize: 16)),
          subtitle: item.attributesString != null ? Text(item.attributesString!) : null,
          trailing: manageMode == CategoryManageMode.delete
              ? Checkbox(value: isSelected, onChanged: onToggleSelect)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.price.toCurrency(context), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    PopupMenuButton<String>(
                      icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: Colors.grey),
                      onSelected: (val) {
                        if (val == 'edit') {
                          onEdit();
                        } else if (val == 'delete') {
                          onDelete();
                        } else if (val == 'restore') {
                          onRestore();
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (item.isAvailable) const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                        if (item.isAvailable) const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: AppColors.danger))),
                        if (!item.isAvailable) const PopupMenuItem(value: 'restore', child: Text('Восстановить', style: TextStyle(color: AppColors.success))),
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
