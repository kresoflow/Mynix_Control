// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Универсальное пустое состояние
// ДОМЕН: lib/core/widgets/ui_kit/app_empty_state.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Размерная шкала для пустых состояний
enum AppEmptyStateSize {
  /// SM: Компактный для выпадающих списков, корзин и табличных строк (высота ~120-140px)
  sm(iconSize: 24, containerSize: 44, titleSize: 13, descSize: 11, spacing: 8),

  /// MD: Стандартный для карточек, вкладок и панелей (высота ~200-240px)
  md(iconSize: 32, containerSize: 60, titleSize: 15, descSize: 12, spacing: 12),

  /// LG: Крупный для главных экранов и пустых разделов приложения (высота ~300+px)
  lg(iconSize: 44, containerSize: 80, titleSize: 18, descSize: 13, spacing: 16);

  final double iconSize;
  final double containerSize;
  final double titleSize;
  final double descSize;
  final double spacing;

  const AppEmptyStateSize({
    required this.iconSize,
    required this.containerSize,
    required this.titleSize,
    required this.descSize,
    required this.spacing,
  });
}

/// Универсальный компонент пустого состояния (Empty State) в стиле Linear & Stripe.
/// 
/// Предотвращает разрозненную верстку заглушек «Ничего не найдено» или «Корзина пуста»
/// по различным экранам приложения.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final AppEmptyStateSize size;
  final Color? customColor;
  final bool showBorder;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.size = AppEmptyStateSize.md,
    this.customColor,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = customColor ?? AppColors.brandPrimary;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Иконка в мягком полупрозрачном контейнере ───────────────
            Container(
              width: size.containerSize,
              height: size.containerSize,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(size.containerSize * 0.3),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.28 : 0.16),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: size.iconSize,
                color: accent,
              ),
            ),
            SizedBox(height: size.spacing),

            // ── Заголовок ──────────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: size.titleSize,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),

            // ── Описание (опционально) ─────────────────────────────────
            if (description != null) ...[
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: size.descSize,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // ── Кнопка действия (опционально) ──────────────────────────
            if (action != null) ...[
              SizedBox(height: size.spacing + 4),
              action!,
            ],
          ],
        ),
      ),
    );

    if (showBorder) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
