// ==============================================================================
// УНИФИЦИРОВАННЫЙ КАРКАС МОДАЛЬНЫХ ОКОН (APP DIALOG SCAFFOLD V2)
// ==============================================================================
//
// [ИНВАРИАНТ] Полное отсутствие захардкоженных синих цветов (#242C3D).
// Строгое соблюдение палитр Ocean, Cream, Ember и адаптивности под мобилки.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Стандартные размеры диалоговых окон
enum AppDialogSize {
  /// Компактный для простых форм и подтверждений (440 px)
  sm,

  /// Средний для карточек клиентов CRM и настроек (720 px)
  md,

  /// Широкий для складских накладных и спецификаций (1080 px)
  lg,
}

/// [UI-KIT] Единый каркас модального диалога системы
class AppDialogScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget body;
  final Widget? bottomSummary;
  final List<Widget> actions;
  final AppDialogSize? dialogSize;
  final double? maxWidth;
  final double? maxHeight;
  final Color? iconColor;

  const AppDialogScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.body,
    this.bottomSummary,
    required this.actions,
    this.dialogSize,
    this.maxWidth,
    this.maxHeight,
    this.iconColor,
  });

  double _resolveWidth() {
    if (maxWidth != null) return maxWidth!;
    switch (dialogSize) {
      case AppDialogSize.sm:
        return 440;
      case AppDialogSize.md:
        return 720;
      case AppDialogSize.lg:
      default:
        return 1080;
    }
  }

  double _resolveHeight() {
    if (maxHeight != null) return maxHeight!;
    switch (dialogSize) {
      case AppDialogSize.sm:
        return 520;
      case AppDialogSize.md:
        return 680;
      case AppDialogSize.lg:
      default:
        return 850;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    final primary = iconColor ?? AppColors.brandPrimary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final footerBg = isDark ? AppColors.darkCard : AppColors.lightBg;

    final resolvedWidth = _resolveWidth();
    final resolvedHeight = _resolveHeight();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      child: Container(
        width: isMobile ? size.width : resolvedWidth,
        height: isMobile ? size.height * 0.94 : resolvedHeight,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadii.dialogRadius,
          border: Border.all(color: borderColor),
          boxShadow: AppShadows.deep,
        ),
        child: Column(
          children: [
            // ─── 1. Шапка модального окна ───
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
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
                          style: AppTextStyles.h3.copyWith(
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
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),

            // ─── 2. Скроллируемое тело ───
            Expanded(
              child: ClipRRect(
                child: body,
              ),
            ),

            // ─── 3. Подвал с действиями ───
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: footerBg,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadii.dialog),
                ),
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bottomSummary != null) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: bottomSummary!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions
                        .map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: a,
                          ),
                        )
                        .toList(),
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
