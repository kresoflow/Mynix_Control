// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Компактный диалог ввода (AppDialog)
// ДОМЕН: lib/core/widgets/app_dialog.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Официальный эталон компактных модальных окон Kreso Flow:
// 1. Предназначен для компактных форм, ввода данных, настроек и подтверждений.
// 2. Естественная высота контента (mainAxisSize: MainAxisSize.min, wrap-content).
// 3. Стандартная ширина: 440–480 px (адаптивно поджимается на смартфонах).
// 4. Гармоничная акцентная плашка иконки, чистый заголовок и нативный футер.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_save_shortcut_scope.dart';

/// [UI-KIT] Официальный компактный модальный диалог системы
class AppDialog extends StatelessWidget {
  /// Заголовок модального окна
  final String title;

  /// Опциональный подзаголовок или пояснение
  final String? subtitle;

  /// Иконка карточки в шапке
  final IconData icon;

  /// Содержимое диалога (форма, поля ввода)
  final Widget content;

  /// Кнопки действий в подвале (например, [Отмена], [Сохранить])
  final List<Widget> actions;

  /// Ширина окна (по умолчанию 450 px)
  final double width;

  /// Флаг деструктивного действия (красный акцент иконки)
  final bool isDestructive;

  /// Опциональный цвет иконки
  final Color? iconColor;

  /// Обратный вызов при закрытии окна крестиком
  final VoidCallback? onClose;

  /// Быстрое сохранение формы по хоткею Ctrl + S / Cmd + S
  final VoidCallback? onSave;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.content,
    required this.actions,
    this.width = 450,
    this.isDestructive = false,
    this.iconColor,
    this.onClose,
    this.onSave,
  });

  void _triggerSave(BuildContext context) {
    if (onSave != null) {
      onSave!();
      return;
    }
    for (final action in actions.reversed) {
      if (action is AppButton && action.onPressed != null && !action.isLoading) {
        action.onPressed!();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppSaveShortcutScope(
      onSave: () => _triggerSave(context),
      onCancel: () {
        if (onClose != null) {
          onClose!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: 24),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
        width: isMobile ? screenWidth - 24 : width,
        constraints: BoxConstraints(maxWidth: width),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadii.dialogRadius,
          border: Border.all(color: borderColor),
          boxShadow: AppShadows.deep,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. Шапка ──────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor?.withValues(alpha: 0.15),
                      gradient: iconColor == null
                          ? (isDestructive
                              ? LinearGradient(
                                  colors: [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)],
                                )
                              : AppColors.brandGradient)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h2.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            fontSize: isMobile ? 18 : null,
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
                    icon: Icon(
                      PhosphorIconsRegular.x,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                    onPressed: onClose ?? () => Navigator.maybePop(context),
                    tooltip: 'Закрыть',
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── 2. Контент ────────────────────────────────────────────
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
                child: content,
              ),
            ),
            const SizedBox(height: 20),

            // ─── 3. Футер (Кнопки) ─────────────────────────────────────
            if (actions.isNotEmpty)
              Builder(
                builder: (context) {
                  final cleanActions = actions.where((w) => w is! SizedBox).toList();
                  return Padding(
                    padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 0, isMobile ? 16 : 28, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (int i = 0; i < cleanActions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          cleanActions[i],
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
    );
  }
}
