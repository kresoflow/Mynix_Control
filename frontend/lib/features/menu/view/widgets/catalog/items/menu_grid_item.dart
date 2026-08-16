import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../catalog_enums.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

class MenuGridItem extends StatelessWidget {
  final MenuItem item;
  final CategoryManageMode manageMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const MenuGridItem({
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
    Color accentColor = AppColors.brandPrimary;
    
    if (!item.isAvailable) {
      accentColor = Colors.grey;
    }

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
      final cleanName = effectiveIcon.startsWith('icon:') ? effectiveIcon.substring(5) : effectiveIcon;
      if (IconHelper.availableIcons.contains(cleanName)) {
        finalIconWidget = IconHelper.buildIcon(
          effectiveIcon,
          size: 32,
          color: accentColor,
        );
      }
    }

    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.5,
      child: AppCard(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                if (finalIconWidget != null)
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withAlpha(50)),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(20),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: finalIconWidget,
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
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.attributesString != null) ...[
                          const SizedBox(height: 2),
                          Text(item.attributesString!, style: AppTextStyles.caption.copyWith(fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBg : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: accentColor.withAlpha(80)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          () {
                            if (item.variationPrices != null && item.variationPrices!.isNotEmpty) {
                              final prices = item.variationPrices!.cast<num>();
                              if (prices.length > 3) {
                                final minPrice = prices.reduce((num a, num b) => a < b ? a : b);
                                return 'От ${minPrice.toCurrency(context)}';
                              }
                              return prices.map((p) => p.toCurrency(context)).join(' | ');
                            }
                            return (item.price as num).toCurrency(context);
                          }(),
                          style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: accentColor),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (manageMode == CategoryManageMode.delete)
              Positioned(top: 4, right: 4, child: Checkbox(value: isSelected, onChanged: onToggleSelect, activeColor: accentColor))
            else if (manageMode == CategoryManageMode.none)
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
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
              ),
          ],
        ),
      ),
    );
  }
}