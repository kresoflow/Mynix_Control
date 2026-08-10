import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

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
    String? effectiveIcon = widget.item.icon;
    
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
        final category = categoryState.categories.firstWhere((c) => c.id.toString() == widget.item.categoryId);
        if (effectiveIcon == null || effectiveIcon.isEmpty) {
          effectiveIcon = category.getInheritedIcon(categoryState.categories);
        }
      }
    } catch (_) {}

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget? finalIconWidget;
    if (effectiveIcon != null && effectiveIcon.isNotEmpty) {
      finalIconWidget = IconHelper.buildIcon(
        effectiveIcon,
        size: isMobile ? 24 : 32,
        color: AppColors.brandPrimary,
      );
    }

    return MouseRegion(
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
              color: isDark ? const Color(0xFF1E2128) : Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
              border: Border.all(
                color: AppColors.brandPrimary.withValues(alpha: _isHovered ? 0.3 : 0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: _isHovered ? 0.15 : 0.05),
                  blurRadius: _isHovered ? 24 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (finalIconWidget != null) ...[
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: isMobile ? 40 : 56,
                      height: isMobile ? 40 : 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: finalIconWidget,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.item.cleanName,
                          style: AppTextStyles.h3.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            fontWeight: FontWeight.w700,
                            fontSize: isMobile ? 12 : null,
                            letterSpacing: 0.3,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.item.attributesString != null) ...[
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            widget.item.attributesString!,
                            style: AppTextStyles.caption.copyWith(
                              height: 1.2,
                              fontSize: isMobile ? 10 : null,
                              color: isDark 
                                  ? AppColors.darkSubtext 
                                  : AppColors.lightSubtext,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 12, vertical: isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: _isHovered ? 0.9 : 0.1),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        () {
                          if (widget.item.variationPrices != null && widget.item.variationPrices!.isNotEmpty) {
                            final List<num> prices = (widget.item.variationPrices as List).cast<num>();
                            if (prices.length > 3) {
                              final num minPrice = prices.reduce((num a, num b) => a < b ? a : b);
                              return 'От ${CurrencyFormatter.format(context, minPrice)}';
                            }
                            return prices.map((dynamic p) => CurrencyFormatter.format(context, p as num)).join(' | ');
                          }
                          return CurrencyFormatter.format(context, widget.item.price as num);
                        }(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w800,
                          color: _isHovered ? Colors.white : AppColors.brandPrimary,
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
    );
  }
}
