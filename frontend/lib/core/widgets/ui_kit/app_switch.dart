// ==============================================================================
// УНИФИЦИРОВАННЫЙ КОМПОНЕНТ ПЕРЕКЛЮЧАТЕЛЯ (APP SWITCH / TOGGLE)
// ==============================================================================
//
// [ИНВАРИАНТ] Никаких Material 3 ripple-ореолов и захардкоженных цветов.
// Идеальная интеграция с AppMotion и палитрами темы (Ocean, Cream, Ember).
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Размер тумблера
enum AppSwitchSize {
  /// Компактный для таблиц и плотных списков (36x20 px)
  sm,

  /// Стандартный для модалок и настроек (44x24 px)
  md,
}

/// [UI-KIT] Стандартизированный тумблер включения/выключения
class AppSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final AppSwitchSize size;
  final String? label;
  final String? description;
  final bool disabled;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = AppSwitchSize.md,
    this.label,
    this.description,
    this.disabled = false,
  });

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch> {
  bool _isHovered = false;

  void _handleTap() {
    if (widget.disabled || widget.onChanged == null) return;
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double width = widget.size == AppSwitchSize.sm ? 36 : 44;
    final double height = widget.size == AppSwitchSize.sm ? 20 : 24;
    final double thumbSize = widget.size == AppSwitchSize.sm ? 16 : 20;
    const double padding = 2.0;

    final activeTrackColor = AppColors.brandPrimary;
    final inactiveTrackColor = isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder.withValues(alpha: 0.9);

    final trackColor = widget.value ? activeTrackColor : inactiveTrackColor;

    final Widget switchWidget = MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: AppMotion.fastDuration,
          opacity: widget.disabled ? 0.45 : 1.0,
          child: AnimatedContainer(
            duration: AppMotion.fastDuration,
            curve: AppMotion.standardCurve,
            width: width,
            height: height,
            padding: const EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(
                color: _isHovered && !widget.disabled
                    ? AppColors.brandPrimary.withValues(alpha: 0.4)
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: widget.value && !widget.disabled
                  ? [
                      BoxShadow(
                        color: AppColors.brandPrimary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedAlign(
              duration: AppMotion.fastDuration,
              curve: AppMotion.standardCurve,
              alignment: widget.value
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.label == null) {
      return switchWidget;
    }

    return InkWell(
      onTap: widget.disabled ? null : _handleTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            switchWidget,
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.description!,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
