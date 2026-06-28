import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/pos/models/menu_item.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:retail_os_frontend/core/utils/icon_helper.dart';
import '../catalog_enums.dart';
import '../catalog_icons.dart';

class MenuGridItem extends StatelessWidget {
  final MenuItem item;
  final CategoryManageMode manageMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuGridItem({
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
            customCategoryIcon = buildCategoryIcon(category.name, size: 32, color: AppColors.brandPrimary);
          }
        } catch (_) {}
      }
    }

    return AppCard(
      onTap: onTap,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: customCategoryIcon ?? IconHelper.buildIcon(
                      effectiveIcon,
                      fallback: item.isRetail ? PhosphorIconsRegular.package : PhosphorIconsRegular.hamburger,
                      size: 32,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.cleanName,
                        style: AppTextStyles.h3.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.attributesString != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.attributesString!,
                          style: AppTextStyles.caption.copyWith(
                            height: 1.3,
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText.withOpacity(0.7) : AppColors.lightText.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${item.price.toInt()} с',
                      style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (manageMode == CategoryManageMode.delete)
            Positioned(top: 4, right: 4, child: Checkbox(value: isSelected, onChanged: onToggleSelect))
          else if (manageMode == CategoryManageMode.none)
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  else if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
