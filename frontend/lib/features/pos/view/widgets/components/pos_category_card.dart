import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/core/utils/icon_helper.dart';

class PosCategoryCard extends StatefulWidget {
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
  State<PosCategoryCard> createState() => _PosCategoryCardState();
}

class _PosCategoryCardState extends State<PosCategoryCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    String? effectiveIcon = widget.cat.icon;
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      effectiveIcon = widget.cat.getInheritedIcon(catState.categories);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final borderColor = _isHovered
        ? widget.accent.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder.withValues(alpha: 0.8));

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
          scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
              boxShadow: _isHovered ? AppShadows.hoverCard : AppShadows.card,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isMobile ? 48 : 64,
                  height: isMobile ? 48 : 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: isDark ? 0.16 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: (effectiveIcon == null || effectiveIcon.isEmpty)
                      ? Text(
                          widget.cat.name.isNotEmpty ? widget.cat.name[0].toUpperCase() : '?',
                          style: AppTextStyles.h2.copyWith(
                            color: widget.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 22 : 28,
                          ),
                        )
                      : IconHelper.buildIcon(
                          effectiveIcon,
                          size: isMobile ? 24 : 34,
                          color: widget.accent,
                        ),
                ),
                SizedBox(height: isMobile ? 8 : 14),
                Text(
                  widget.cat.name,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 13 : 15,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
