// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Компактный карточный диалог (AppCardDialog)
// ДОМЕН: lib/core/widgets/ui_kit/app_card_dialog.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Эталон компактного модального окна в стиле Kreso Flow:
// 1. Естественная высота контента (mainAxisSize: MainAxisSize.min, без пустых зон).
// 2. Бесшовный чистый подвал (actions на светлом surface-фоне без серой полосы).
// 3. Сбалансированная ширина по умолчанию (680 px для операционных документов).
// 4. Защита кнопок действий от сжатия и слипания (гарантированный gap: 10).
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// [UI-KIT] Компактный карточный диалог с естественной высотой и бесшовным футером.
class AppCardDialog extends StatelessWidget {
  /// Заголовок модального окна
  final String title;

  /// Подзаголовок или пояснение под заголовком
  final String? subtitle;

  /// Иконка карточки в шапке
  final IconData icon;

  /// Акцентный цвет иконки (по умолчанию AppColors.brandPrimary)
  final Color? iconColor;

  /// Содержимое диалога (форма, таблица, поля ввода)
  final Widget body;

  /// Кнопки действий в подвале (например, [Отмена], [Провести])
  final List<Widget> actions;

  /// Опциональный виджет итогов над кнопками футера (сумма, количество)
  final Widget? bottomSummary;

  /// Ширина окна (по умолчанию 680 px — эталон операционных документов)
  final double width;

  /// Максимальная ширина окна
  final double? maxWidth;

  /// Максимальная высота окна (по умолчанию 90% экрана)
  final double? maxHeight;

  /// Обратный вызов при закрытии окна крестиком
  final VoidCallback? onClose;

  /// Внутренние отступы содержимого body (по умолчанию 24, 16, 24, 0)
  final EdgeInsetsGeometry? contentPadding;

  /// Опциональный оверлей (шторка-корзина внутри модалки)
  final Widget? overlay;

  const AppCardDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    required this.body,
    required this.actions,
    this.bottomSummary,
    this.width = 680,
    this.maxWidth,
    this.maxHeight,
    this.onClose,
    this.contentPadding,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 768;

    final primary = iconColor ?? AppColors.brandPrimary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    final effectiveWidth = isMobile ? media.size.width - 24 : width;
    final effectiveMaxWidth = maxWidth ?? width;
    final effectiveMaxHeight = maxHeight ?? (media.size.height * 0.90);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      child: Container(
        width: effectiveWidth,
        constraints: BoxConstraints(
          maxWidth: effectiveMaxWidth,
          maxHeight: effectiveMaxHeight,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadii.dialogRadius,
          border: Border.all(color: borderColor),
          boxShadow: AppShadows.deep,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // ─── 1. Шапка модального окна ────────────────────────────────────
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
                  // Акцентная плашка иконки
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: primary, size: 20),
                  ),
                  const SizedBox(width: 14),

                  // Заголовок и подзаголовок
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
                              color: subtextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Кнопка закрытия
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onClose ?? () => Navigator.maybePop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          PhosphorIconsRegular.x,
                          size: 20,
                          color: subtextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── 2. Скроллируемое тело ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding ??
                    EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      16,
                      isMobile ? 16 : 24,
                      0,
                    ),
                child: body,
              ),
            ),

            // ─── 3. Бесшовный подвал с действиями ────────────────────────────
            if (actions.isNotEmpty || bottomSummary != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  14,
                  isMobile ? 16 : 24,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (bottomSummary != null) ...[
                      bottomSummary!,
                      const SizedBox(height: 14),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions
                          .map(
                            (btn) => Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: btn,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: overlay == null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: overlay != null
                    ? KeyedSubtree(
                        key: const ValueKey('app_card_dialog_overlay_active'),
                        child: overlay!,
                      )
                    : const SizedBox.shrink(key: ValueKey('app_card_dialog_overlay_none')),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
