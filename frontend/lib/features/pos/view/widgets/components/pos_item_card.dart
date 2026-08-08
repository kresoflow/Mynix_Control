import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/core/widgets/app_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_icons.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

class PosItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const PosItemCard({
    super.key,
    required this.item,
    required this.onTap,
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
        size: 28,
        color: AppColors.brandPrimary,
      );
    }

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (finalIconWidget != null) ...[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: finalIconWidget!,
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      item.cleanName,
                      style: AppTextStyles.h3.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkText
                            : AppColors.lightText,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.attributesString != null) ...[
                    SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        item.attributesString!,
                        style: AppTextStyles.caption.copyWith(
                          height: 1.2,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkText.withValues(alpha: 0.7) 
                              : AppColors.lightText.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    () {
                      if (item.variationPrices != null && item.variationPrices!.isNotEmpty) {
                        final List<num> prices = (item.variationPrices as List).cast<num>();
                        if (prices.length > 3) {
                          final num minPrice = prices.reduce((num a, num b) => a < b ? a : b);
                          return 'От ${CurrencyFormatter.format(context, minPrice)}';
                        }
                        return prices.map((dynamic p) => CurrencyFormatter.format(context, p as num)).join(' | ');
                      }
                      return CurrencyFormatter.format(context, item.price as num);
                    }(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
