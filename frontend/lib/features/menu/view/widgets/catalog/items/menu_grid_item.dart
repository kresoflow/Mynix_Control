import 'package:flutter/material.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../catalog_enums.dart';
import '../catalog_deletion_dialogs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/color_picker/color_picker_utils.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_status_badge.dart';

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
    Color? inheritedColor;
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
        final colorHex = category.getInheritedColor(categoryState.categories);
        inheritedColor = ColorPickerUtils.parseHex(colorHex);
      }
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = !item.isAvailable
        ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
        : (inheritedColor ?? AppColors.brandPrimary);

    Widget finalIconWidget;
    if (effectiveIcon != null && effectiveIcon.isNotEmpty) {
      final cleanName = effectiveIcon.startsWith('icon:') ? effectiveIcon.substring(5) : effectiveIcon;
      if (IconHelper.availableIcons.contains(cleanName)) {
        finalIconWidget = IconHelper.buildIcon(
          effectiveIcon,
          size: 28,
          color: accentColor,
        );
      } else {
        finalIconWidget = Icon(
          item.isRetail ? PhosphorIconsRegular.storefront : PhosphorIconsRegular.bowlFood,
          size: 26,
          color: accentColor,
        );
      }
    } else {
      finalIconWidget = Icon(
        item.isRetail ? PhosphorIconsRegular.storefront : PhosphorIconsRegular.bowlFood,
        size: 26,
        color: accentColor,
      );
    }

    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.5,
      child: AppCard(
        onTap: onTap,
        isSelected: isSelected,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: AppRadii.cardRadius,
                        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                        boxShadow: AppShadows.card,
                      ),
                      child: finalIconWidget,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        () {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final hasFlavor = item.flavorString != null && item.flavorString!.trim().isNotEmpty;
                          final clean = item.cleanName.trim();
                          final showFlavorInTitle = hasFlavor && !clean.toLowerCase().contains(item.flavorString!.toLowerCase().trim());

                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: clean,
                                  style: AppTextStyles.h3.copyWith(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                                if (showFlavorInTitle) ...[
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: item.flavorString!.trim(),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }(),
                        if (item.variationsSummary != null) ...[
                          const SizedBox(height: 6),
                          AppStatusBadge(
                            label: item.variationsSummary!,
                            variant: AppBadgeVariant.info,
                            height: 20,
                          ),
                        ] else if (item.attributesString != null) ...[
                          const SizedBox(height: 6),
                          AppStatusBadge(
                            label: item.attributesString!,
                            variant: AppBadgeVariant.neutral,
                            height: 20,
                          ),
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
                        borderRadius: AppRadii.maxRadius,
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
                                final maxPrice = prices.reduce((num a, num b) => a > b ? a : b);
                                return '${minPrice.toCurrency(context)} — ${maxPrice.toCurrency(context)}';
                              }
                              return prices.map((p) => p.toCurrency(context)).join('  ');
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
              ),
          ],
        ),
      ),
    );
  }
}