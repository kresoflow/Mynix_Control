// ==============================================================================
// МОДУЛЬ: Ядро дизайн-системы / Универсальная карточка KPI и аналитических метрик
// ДОМЕН: lib/core/widgets/ui_kit/app_kpi_card.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Модель динамического тренда показателя (дельта / динамика)
class AppKpiTrend {
  final String label;
  final bool isPositive;
  final bool isNeutral;

  const AppKpiTrend({
    required this.label,
    this.isPositive = true,
    this.isNeutral = false,
  });

  const AppKpiTrend.up(this.label) : isPositive = true, isNeutral = false;
  const AppKpiTrend.down(this.label) : isPositive = false, isNeutral = false;
  const AppKpiTrend.neutral(this.label) : isPositive = false, isNeutral = true;
}

/// Универсальная карточка KPI (Metric Card) в стиле Stripe & Linear.
/// 
/// Унифицирует вывод ключевых метрик в Аналитике, CRM, Складе и сменах.
/// Поддерживает светлую/тёмную темы, моноширинные числа и ховер-эффект.
class AppKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final AppKpiTrend? trend;
  final bool isMono;
  final bool compact;
  final VoidCallback? onTap;

  const AppKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.trend,
    this.isMono = true,
    this.compact = false,
    this.onTap,
  });

  @override
  State<AppKpiCard> createState() => _AppKpiCardState();
}

class _AppKpiCardState extends State<AppKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.color ?? AppColors.brandPrimary;
    final bg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
        : const EdgeInsets.all(18);

    return MouseRegion(
      onEnter: widget.onTap != null ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.onTap != null ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          padding: padding,
          decoration: BoxDecoration(
            color: _isHovered ? (isDark ? AppColors.darkCardHover : AppColors.lightBg) : bg,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: _isHovered ? accent.withValues(alpha: 0.6) : border,
              width: _isHovered ? 1.4 : 1.0,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: accent.withValues(alpha: isDark ? 0.20 : 0.12), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 1. Иконка в акцентном контейнере ───────────────────
              Container(
                width: widget.compact ? 38 : 46,
                height: widget.compact ? 38 : 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(widget.compact ? 10 : 12),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.32 : 0.20),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  size: widget.compact ? 18 : 22,
                  color: accent,
                ),
              ),
              const SizedBox(width: 14),

              // ── 2. Блок данных (Заголовок, Число, Подпись) ─────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: widget.compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.value,
                      style: widget.isMono
                          ? GoogleFonts.jetBrainsMono(
                              fontSize: widget.compact ? 16 : 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                              letterSpacing: -0.4,
                            )
                          : AppTextStyles.h2.copyWith(
                              fontSize: widget.compact ? 16 : 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null || widget.trend != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.trend != null) ...[
                            _buildTrendBadge(widget.trend!, isDark),
                            if (widget.subtitle != null) const SizedBox(width: 6),
                          ],
                          if (widget.subtitle != null)
                            Flexible(
                              child: Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge(AppKpiTrend trend, bool isDark) {
    Color fg;
    Color bg;
    IconData icon;

    if (trend.isNeutral) {
      fg = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
      bg = fg.withValues(alpha: 0.12);
      icon = PhosphorIconsRegular.minus;
    } else if (trend.isPositive) {
      fg = AppColors.success;
      bg = fg.withValues(alpha: isDark ? 0.18 : 0.10);
      icon = PhosphorIconsRegular.trendUp;
    } else {
      fg = AppColors.danger;
      bg = fg.withValues(alpha: isDark ? 0.18 : 0.10);
      icon = PhosphorIconsRegular.trendDown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            trend.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
