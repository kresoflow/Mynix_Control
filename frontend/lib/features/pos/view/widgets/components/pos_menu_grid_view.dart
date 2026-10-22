import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/color_picker/color_picker_utils.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/pos/view/widgets/components/pos_category_card.dart';
import 'package:kreso_frontend/features/pos/view/widgets/components/pos_item_card.dart';
import 'package:kreso_frontend/features/pos/view/widgets/helpers/pos_item_click_handler.dart';

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
        isMobile ? 10 : 24,
        isMobile ? 10 : 24,
        isMobile ? 10 : 24,
        isMobile ? 120 : 24,
      ),
      gridDelegate: isMobile
          ? const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.88,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: posSettings.columnsCount,
              childAspectRatio: 0.85,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
      itemCount: categories.length + items.length,
      itemBuilder: (context, index) {
        if (index < categories.length) {
          final cat = categories[index];
          Color? customColor;
          try {
            final catState = context.read<CategoryBloc>().state;
            if (catState is CategoryLoaded) {
              final hex = cat.getInheritedColor(catState.categories);
              customColor = ColorPickerUtils.parseHex(hex);
            } else {
              customColor = ColorPickerUtils.parseHex(cat.color);
            }
          } catch (_) {
            customColor = ColorPickerUtils.parseHex(cat.color);
          }
          final accent = (posSettings.enableRainbowColors && customColor != null)
              ? customColor
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
