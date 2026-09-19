import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';

class RecipeDishTile extends StatelessWidget {
  final dynamic item;
  final bool isSelected;
  final Map<String, dynamic>? summary;
  final CategoryState catState;
  final VoidCallback onTap;

  const RecipeDishTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.summary,
    required this.catState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasRecipe = summary?['has_recipe'] == true;
    final double cost = (summary?['total_cost'] as num?)?.toDouble() ?? 0.0;
    final double marginPercent = item.price > 0 && cost > 0
        ? ((item.price - cost) / item.price) * 100
        : 0.0;

    String? iconStr = item.icon;
    if ((iconStr == null || iconStr.isEmpty) && catState is CategoryLoaded) {
      final loadedState = catState as CategoryLoaded;
      final cat = loadedState.categories
          .where((c) => c.id.toString() == item.categoryId)
          .firstOrNull;
      iconStr = cat?.getInheritedIcon(loadedState.categories);
    }
    final bool hasIcon = iconStr != null &&
        iconStr.isNotEmpty &&
        (IconHelper.getIcon(iconStr) != null || iconStr.startsWith('svg:'));

    return AppNavTile(
      title: item.cleanName,
      subtitle: hasRecipe
          ? '${cost.toStringAsFixed(0)} с • ${marginPercent.toStringAsFixed(0)}% маржа'
          : 'Без состава',
      leading: hasIcon
          ? IconHelper.buildIcon(
              iconStr,
              size: 16,
              color: isSelected
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            )
          : null,
      depth: 1,
      size: AppNavTileSize.md,
      isSelected: isSelected,
      trailing: Text(
        '${item.price.toStringAsFixed(0)} с',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        ),
      ),
      onTap: onTap,
    );
  }
}
