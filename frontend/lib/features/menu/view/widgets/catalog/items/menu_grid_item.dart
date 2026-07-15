import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../catalog_enums.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

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
    // OLED Liquid Design Logic
    Color accentColor = AppColors.brandPrimary;
    IconData itemIcon = PhosphorIconsRegular.hamburger;

    if (item.isRetail) {
      final catName = item.categoryName?.toLowerCase() ?? '';
      if (catName.contains('напит') || catName.contains('сок') || catName.contains('вод')) {
        itemIcon = PhosphorIconsRegular.drop; // Liquid vibe
        accentColor = Colors.cyanAccent.shade400;
      } else {
        itemIcon = PhosphorIconsRegular.package;
        accentColor = Colors.purpleAccent.shade400;
      }
    } else {
      // Dish
      itemIcon = PhosphorIconsRegular.hamburger;
      accentColor = AppColors.brandPrimary;
    }

    return AppCard(
      onTap: onTap,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
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
                    child: Icon(itemIcon, size: 26, color: accentColor),
                  ),
                ),
                SizedBox(height: 8),
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
                        SizedBox(height: 2),
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
                        item.variationPrices != null && item.variationPrices!.isNotEmpty
                            ? item.variationPrices!.map((p) => (p as num).toCurrency(context)).join(' | ')
                            : '${(item.price as num).toCurrency(context)}',
                        style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w800, color: accentColor),
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
                  } else if (val == 'delete') onDelete();
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