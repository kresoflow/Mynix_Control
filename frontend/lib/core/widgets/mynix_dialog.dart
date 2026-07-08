import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_shadows.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Универсальный компонент для всех модальных окон в Mynix Control.
/// Заменяет стандартный AlertDialog, обеспечивая единый премиальный стиль.
class MynixDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;
  final List<Widget> actions;
  final double width;
  final bool isDestructive;

  const MynixDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    required this.actions,
    this.width = 450,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadii.dialogRadius,
          boxShadow: AppShadows.deep,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Шапка ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: isDestructive
                          ? LinearGradient(colors: [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)])
                          : AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Закрыть',
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Контент ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: content,
            ),
            const SizedBox(height: 28),

            // ── Футер (Кнопки) ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
