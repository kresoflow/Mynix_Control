import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/menu/view/widgets/catalog/catalog_icons.dart';
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: (effectiveIcon == null || effectiveIcon.isEmpty)
                  ? Text(
                      cat.name.isNotEmpty ? cat.name[0].toUpperCase() : '?',
                      style: AppTextStyles.h2.copyWith(color: accent, fontWeight: FontWeight.bold),
                    )
                  : IconHelper.buildIcon(
                      effectiveIcon,
                      size: 32,
                      color: accent,
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
