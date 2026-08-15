import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_shadows.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class AppDialogScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget body;
  final Widget? bottomSummary;
  final List<Widget> actions;
  final double maxWidth;
  final double maxHeight;
  final Color? iconColor;

  const AppDialogScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.body,
    this.bottomSummary,
    required this.actions,
    this.maxWidth = 1100,
    this.maxHeight = 850,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    final primary = iconColor ?? AppColors.brandPrimary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 12 : 24,
      ),
      child: Container(
        width: maxWidth,
        height: isMobile ? size.height * 0.95 : maxHeight,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadii.dialogRadius,
          border: Border.all(
            color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder,
          ),
          boxShadow: AppShadows.deep,
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 20),
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ─────────────────────────────────────────
            Expanded(
              child: ClipRRect(
                child: body,
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10141D) : AppColors.lightBg,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.dialog)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF242C3D) : AppColors.lightBorder,
                  ),
                ),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (bottomSummary != null) ...[
                          bottomSummary!,
                          const SizedBox(height: 12),
                        ],
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.end,
                          children: actions,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (bottomSummary != null) bottomSummary! else const SizedBox.shrink(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions.map((a) => Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: a,
                          )).toList(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
