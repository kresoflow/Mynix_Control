import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_status_badge.dart';
import 'package:kreso_frontend/core/widgets/color_picker/color_picker_utils.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';

class PosItemCard extends StatefulWidget {
  final dynamic item;
  final VoidCallback onTap;

  const PosItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<PosItemCard> createState() => _PosItemCardState();
}

class _PosItemCardState extends State<PosItemCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color? inheritedColor;
    String? effectiveIcon = widget.item.icon;
    
    // 1. Быстрая валидация иконки за O(1) без создания списков
    if (effectiveIcon != null && effectiveIcon.isNotEmpty && !IconHelper.hasIcon(effectiveIcon)) {
      effectiveIcon = null;
    }
    
    // 2. Мгновенный поиск категории по хэш-таблице O(1) вместо firstWhere
    try {
      final categoryState = context.read<CategoryBloc>().state;
      if (categoryState is CategoryLoaded) {
        final category = categoryState.getById(widget.item.categoryId);
        if (category != null) {
          if (effectiveIcon == null || effectiveIcon.isEmpty) {
            effectiveIcon = category.getInheritedIcon(categoryState.categories);
          }
          final colorHex = category.getInheritedColor(categoryState.categories);
          inheritedColor = ColorPickerUtils.parseHex(colorHex);
        }
      }
    } catch (_) {}

    final posSettings = context.watch<PosSettingsCubit>().state;
    final accentColor = (posSettings.enableRainbowColors && inheritedColor != null)
        ? inheritedColor
        : AppColors.brandPrimary;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget finalIconWidget;
    if (effectiveIcon != null && effectiveIcon.isNotEmpty) {
      if (IconHelper.hasIcon(effectiveIcon)) {
        finalIconWidget = IconHelper.buildIcon(
          effectiveIcon,
          size: isMobile ? 24 : 32,
          color: accentColor,
        );
      } else {
        finalIconWidget = Icon(
          widget.item.isRetail ? PhosphorIconsRegular.storefront : PhosphorIconsRegular.bowlFood,
          size: isMobile ? 22 : 28,
          color: accentColor,
        );
      }
    } else {
      finalIconWidget = Icon(
        widget.item.isRetail ? PhosphorIconsRegular.storefront : PhosphorIconsRegular.bowlFood,
        size: isMobile ? 22 : 28,
        color: accentColor,
      );
    }

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(
                color: accentColor.withValues(alpha: _isHovered ? 0.3 : 0.05),
                width: 1.5,
              ),
              boxShadow: _isHovered ? AppShadows.buttonGlow(accentColor) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: isMobile ? 40 : 56,
                    height: isMobile ? 40 : 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: finalIconWidget,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: () {
                          final hasFlavor = widget.item.flavorString != null &&
                              widget.item.flavorString!.trim().isNotEmpty;
                          final clean = widget.item.cleanName.trim();
                          final showFlavorInTitle = hasFlavor &&
                              !clean.toLowerCase().contains(widget.item.flavorString!.toLowerCase().trim());

                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: clean,
                                  style: AppTextStyles.h3.copyWith(
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isMobile ? 12 : 14,
                                    letterSpacing: 0.3,
                                    height: 1.2,
                                  ),
                                ),
                                if (showFlavorInTitle) ...[
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: widget.item.flavorString!.trim(),
                                    style: isMobile ? AppTextStyles.flavorBadgeMobile : AppTextStyles.flavorBadge,
                                  ),
                                ],
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }(),
                      ),
                      if (widget.item.variationsSummary != null) ...[
                        const SizedBox(height: 6),
                        Flexible(
                          child: AppStatusBadge(
                            label: widget.item.variationsSummary!,
                            variant: AppBadgeVariant.info,
                            height: 20,
                          ),
                        ),
                      ] else if (widget.item.attributesString != null) ...[
                        const SizedBox(height: 6),
                        Flexible(
                          child: AppStatusBadge(
                            label: widget.item.attributesString!,
                            variant: AppBadgeVariant.neutral,
                            height: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 12, vertical: isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: _isHovered ? 0.9 : 0.1),
                      borderRadius: AppRadii.radiusSm,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        () {
                          if (widget.item.variationPrices != null && widget.item.variationPrices!.isNotEmpty) {
                            final List<num> prices = (widget.item.variationPrices as List).cast<num>();
                            if (prices.length > 3) {
                              final num minPrice = prices.reduce((num a, num b) => a < b ? a : b);
                              final num maxPrice = prices.reduce((num a, num b) => a > b ? a : b);
                              return '${CurrencyFormatter.format(context, minPrice)} — ${CurrencyFormatter.format(context, maxPrice)}';
                            }
                            return prices.map((dynamic p) => CurrencyFormatter.format(context, p as num)).join('  ');
                          }
                          return CurrencyFormatter.format(context, widget.item.price as num);
                        }(),
                        style: (isMobile ? AppTextStyles.cardPriceMobile : AppTextStyles.cardPrice).copyWith(
                          color: _isHovered ? AppColors.white : accentColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
