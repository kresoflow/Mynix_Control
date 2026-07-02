import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import '../catalog_enums.dart';
import '../catalog_icons.dart';
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

  const MenuListItem({
    super.key,
    required this.item,
    required this.manageMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveIcon = item.icon;
    Widget? customCategoryIcon;
    if (effectiveIcon == null || effectiveIcon.isEmpty) {
      final categoryState = context.read<CategoryBloc>().state;
      if (categoryState is CategoryLoaded) {
        try {
          final category = categoryState.categories.firstWhere((c) => c.id.toString() == item.categoryId);
          effectiveIcon = category.getInheritedIcon(categoryState.categories);
          if (effectiveIcon == null || effectiveIcon.isEmpty) {
            customCategoryIcon = buildCategoryIcon(category.name, size: 20, color: AppColors.brandPrimary);
          }
        } catch (_) {}
      }
    }

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: customCategoryIcon ?? IconHelper.buildIcon(
            effectiveIcon,
            fallback: item.isRetail ? PhosphorIconsRegular.package : PhosphorIconsRegular.hamburger,
            size: 20,
            color: AppColors.brandPrimary,
          ),
        ),
        title: Text(item.cleanName, style: const TextStyle(fontSize: 16)),
        subtitle: item.attributesString != null ? Text(item.attributesString!) : null,
        trailing: manageMode == CategoryManageMode.delete
            ? Checkbox(value: isSelected, onChanged: onToggleSelect)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${item.price.toCurrency(context)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  PopupMenuButton<String>(
                    icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'edit') {
                        onEdit();
                      } else if (val == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                      const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}
