import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/core/utils/icon_helper.dart';
import 'package:retail_os_frontend/features/menu/view/widgets/catalog/catalog_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PosCategoryCard extends StatelessWidget {
  final dynamic cat;
  final Color accent;
  final VoidCallback onTap;

  const PosCategoryCard({
    super.key,
    required this.cat,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveIcon = cat.icon;
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      effectiveIcon = cat.getInheritedIcon(catState.categories);
    }

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: (effectiveIcon == null || effectiveIcon.isEmpty)
                  ? buildCategoryIcon(cat.name, size: 32, color: Colors.white)
                  : IconHelper.buildIcon(
                      effectiveIcon,
                      fallback: PhosphorIconsRegular.list,
                      size: 32,
                      color: Colors.white,
                    ),
            ),
            Text(
              cat.name,
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
