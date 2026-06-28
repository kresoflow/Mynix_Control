import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/utils/icon_helper.dart';
import 'package:retail_os_frontend/core/widgets/app_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/menu/view/widgets/catalog/catalog_icons.dart';

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
    Widget? customCategoryIcon;
    if (effectiveIcon == null || effectiveIcon.isEmpty) {
      final categoryState = context.read<CategoryBloc>().state;
      if (categoryState is CategoryLoaded) {
        try {
          final category = categoryState.categories.firstWhere((c) => c.id.toString() == item.categoryId);
          effectiveIcon = category.getInheritedIcon(categoryState.categories);
          if (effectiveIcon == null || effectiveIcon.isEmpty) {
            customCategoryIcon = buildCategoryIcon(category.name, size: 28, color: AppColors.brandPrimary);
          }
        } catch (_) {}
      }
    }

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: customCategoryIcon ?? IconHelper.buildIcon(
                effectiveIcon,
                fallback: item.isRetail ? PhosphorIconsRegular.package : PhosphorIconsRegular.hamburger,
                size: 28,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 10),
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
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.attributesString != null) ...[
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        item.attributesString!,
                        style: AppTextStyles.caption.copyWith(
                          height: 1.2,
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText.withValues(alpha: 0.7) : AppColors.lightText.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkBg 
                    : AppColors.lightBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: AppColors.brandPrimary.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${item.price.toInt()} с',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
