import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_category_card.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/pos_item_card.dart';
import 'package:mynix_frontend/features/pos/view/widgets/helpers/pos_item_click_handler.dart';

class PosMenuGridView extends StatelessWidget {
  final List<dynamic> categories;
  final List<dynamic> items;
  final PosSettingsState posSettings;
  final Function(dynamic cat) onCategoryTap;

  const PosMenuGridView({
    super.key,
    required this.categories,
    required this.items,
    required this.posSettings,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 12 : 24,
        isMobile ? 12 : 24,
        isMobile ? 120 : 24,
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? (screenWidth / 2) - 16 : posSettings.cardSize,
        childAspectRatio: isMobile ? 0.9 : 0.85,
        crossAxisSpacing: isMobile ? 12 : 20,
        mainAxisSpacing: isMobile ? 12 : 20,
      ),
      itemCount: categories.length + items.length,
      itemBuilder: (context, index) {
        if (index < categories.length) {
          final cat = categories[index];
          final accent = posSettings.enableRainbowColors
              ? AppColors.categoryRainbowPalette[index % AppColors.categoryRainbowPalette.length]
              : AppColors.brandPrimary;
          return PosCategoryCard(
            cat: cat,
            accent: accent,
            onTap: () => onCategoryTap(cat),
          );
        } else {
          final item = items[index - categories.length];
          return PosItemCard(
            item: item,
            onTap: () => handlePosItemClick(context, item as MenuItem),
          );
        }
      },
    );
  }
}
