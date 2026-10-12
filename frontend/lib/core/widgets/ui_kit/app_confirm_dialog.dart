// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Стандартный диалог подтверждения действий
// ДОМЕН: lib/core/widgets/ui_kit/app_confirm_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';

/// Стандартизированный диалог подтверждения (Confirm Dialog) в Kreso Flow.
/// 
/// Ликвидирует использование нестилизованного Material `AlertDialog`.
/// Обеспечивает единую эргономику, анимацию появления и поддержку опасных действий.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final IconData? icon;
  final IconData? confirmIcon;
  final Widget? customContent;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Подтвердить',
    this.cancelLabel = 'Отмена',
    this.isDanger = false,
    this.icon,
    this.confirmIcon,
    this.customContent,
  });

  /// Статический вспомогательный метод для быстрого вызова диалога.
  /// 
  /// Возвращает `true`, если пользователь подтвердил действие, иначе `false`.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Подтвердить',
    String cancelLabel = 'Отмена',
    bool isDanger = false,
    IconData? icon,
    IconData? confirmIcon,
    Widget? customContent,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.60),
      transitionDuration: AppMotion.modal,
      pageBuilder: (ctx, anim, secondaryAnim) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        icon: icon,
        confirmIcon: confirmIcon,
        customContent: customContent,
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return AppMotion.scaleFadeTransition(animation: anim, child: child);
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDanger ? AppColors.danger : AppColors.brandPrimary;
    final defaultIcon = isDanger ? PhosphorIconsRegular.warning : PhosphorIconsRegular.question;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadii.dialogRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: AppShadows.deep,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Шапка диалога с акцентной иконкой ───────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.32 : 0.20),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon ?? defaultIcon,
                      size: 20,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 13,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Дополнительный пользовательский контент ─────────────
              if (customContent != null) ...[
                const SizedBox(height: 16),
                customContent!,
              ],

              const SizedBox(height: 24),

              // ── Панель кнопок действий ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppGhostButton(
                    label: cancelLabel,
                    size: AppButtonSize.md,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 12),
                  if (isDanger)
                    AppDangerButton(
                      label: confirmLabel,
                      icon: confirmIcon,
                      size: AppButtonSize.md,
                      onPressed: () => Navigator.of(context).pop(true),
                    )
                  else
                    AppPrimaryButton(
                      label: confirmLabel,
                      icon: confirmIcon,
                      size: AppButtonSize.md,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
