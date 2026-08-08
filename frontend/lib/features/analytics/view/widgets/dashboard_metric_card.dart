import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class DashboardMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color>? gradientColors;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.gradientColors,
  });

  @override
  State<DashboardMetricCard> createState() => _DashboardMetricCardState();
}

class _DashboardMetricCardState extends State<DashboardMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = [AppColors.brandPrimary, AppColors.brandSecondary];
    final activeGradient = widget.gradientColors ?? defaultGradient;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 220;
          
          final iconBox = Container(
            padding: EdgeInsets.all(isCompact ? 10 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: activeGradient,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: activeGradient[1].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: isCompact ? 22 : 28),
          );

          final titleText = Text(
            widget.title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              fontSize: isCompact ? 13 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

          final valueText = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.value,
              style: AppTextStyles.display.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: isCompact ? 22 : 28,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
            ),
          );

          Widget innerContent;
          if (isCompact) {
            innerContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBox,
                const SizedBox(height: 12),
                titleText,
                const SizedBox(height: 4),
                valueText,
              ],
            );
          } else {
            innerContent = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconBox,
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      titleText,
                      const SizedBox(height: 6),
                      valueText,
                    ],
                  ),
                ),
              ],
            );
          }

          return AnimatedScale(
            scale: _isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 20, vertical: isCompact ? 16 : 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? activeGradient[0].withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? activeGradient[1].withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: _isHovered ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: innerContent,
            ),
          );
        },
      ),
    );
  }
}
