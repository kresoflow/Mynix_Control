// ==============================================================================
// УНИФИЦИРОВАННЫЙ СЧЕТЧИК КОЛИЧЕСТВА (APP QUANTITY STEPPER - REDESIGNED 2.0)
// ==============================================================================
//
// [ИНВАРИАНТ] Премиальный тактильный степпер: цельная капсула без резких полос,
// закругленные микро-кнопки [-] и [+] с подсветкой, плюс прямой ввод (Click-to-Type)
// с мгновенной реактивностью (onChanged) и поддержкой точности до 3 знаков (0.015).
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';

/// Размерная шкала для счетчиков количества
enum AppStepperSize {
  /// SM (28px): Компактный для табличных строк, накладных и спецификаций
  sm(height: 28, btnSize: 22, valueWidth: 46, iconSize: 11, fontSize: 12, radius: 8),

  /// MD (34px): Стандартный для корзин и карточек заказов
  md(height: 34, btnSize: 26, valueWidth: 54, iconSize: 13, fontSize: 13, radius: 9),

  /// LG (42px): Просторный для сенсорных экранов кассы (POS Touch)
  lg(height: 42, btnSize: 32, valueWidth: 64, iconSize: 16, fontSize: 15, radius: 10);

  final double height;
  final double btnSize;
  final double valueWidth;
  final double iconSize;
  final double fontSize;
  final double radius;

  const AppStepperSize({
    required this.height,
    required this.btnSize,
    required this.valueWidth,
    required this.iconSize,
    required this.fontSize,
    required this.radius,
  });
}

/// [UI-KIT] Премиальный степпер с микро-кнопками и прямым вводом (Click-to-Type)
class AppQuantityStepper extends StatefulWidget {
  final num value;
  final ValueChanged<num> onChanged;
  final num min;
  final num? max;
  final num step;
  final String? unit;
  final bool allowDecimals;
  final AppStepperSize size;
  final VoidCallback? onRemove;

  const AppQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.step = 1,
    this.unit,
    this.allowDecimals = false,
    this.size = AppStepperSize.md,
    this.onRemove,
  });

  @override
  State<AppQuantityStepper> createState() => _AppQuantityStepperState();
}

class _AppQuantityStepperState extends State<AppQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _submitDirectInput();
    }
  }

  void _handleTypingChange(String text) {
    final cleaned = text.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return;
    final parsed = double.tryParse(cleaned);
    if (parsed != null && parsed >= widget.min) {
      final clamped = parsed.clamp(widget.min.toDouble(), (widget.max ?? double.infinity).toDouble());
      final rounded = double.parse(clamped.toStringAsFixed(3));
      widget.onChanged(widget.allowDecimals ? rounded : clamped.toInt());
    }
  }

  void _submitDirectInput() {
    setState(() => _isEditing = false);
    final text = _controller.text.replaceAll(',', '.').trim();
    final parsed = double.tryParse(text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min.toDouble(), (widget.max ?? double.infinity).toDouble());
      final rounded = double.parse(clamped.toStringAsFixed(3));
      widget.onChanged(widget.allowDecimals ? rounded : clamped.toInt());
      _controller.text = _formatValue(rounded);
    } else {
      _controller.text = _formatValue(widget.value);
    }
  }

  String _formatValue(num val) {
    if (val == 0) return '0';
    if (widget.allowDecimals) {
      final str = val.toDouble().toStringAsFixed(3);
      final trimmed = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return trimmed.isEmpty ? '0' : trimmed;
    }
    return val.toInt().toString();
  }

  void _handleDecrement() {
    if (widget.value <= widget.min) {
      widget.onRemove?.call();
      return;
    }
    final next = (widget.value - widget.step).clamp(widget.min, widget.max ?? double.infinity);
    final rounded = double.parse(next.toDouble().toStringAsFixed(3));
    widget.onChanged(widget.allowDecimals ? rounded : rounded.toInt());
  }

  void _handleIncrement() {
    if (widget.max != null && widget.value >= widget.max!) return;
    final next = (widget.value + widget.step).clamp(widget.min, widget.max ?? double.infinity);
    final rounded = double.parse(next.toDouble().toStringAsFixed(3));
    widget.onChanged(widget.allowDecimals ? rounded : rounded.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final isTrashAction = widget.value <= widget.min && widget.onRemove != null;

    return Container(
      height: widget.size.height,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.size.radius),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Микро-кнопка [-] ──
          _MicroButton(
            icon: isTrashAction ? PhosphorIconsBold.trash : PhosphorIconsBold.minus,
            iconColor: isTrashAction ? AppColors.danger : null,
            size: widget.size,
            onTap: _handleDecrement,
          ),

          // ── Центральное значение (Click-to-Type с постоянной единицей) ──
          GestureDetector(
            onTap: () {
              setState(() => _isEditing = true);
              _focusNode.requestFocus();
              _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: BoxConstraints(minWidth: widget.size.valueWidth),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEditing)
                    SizedBox(
                      width: widget.size.valueWidth,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.numberWithOptions(decimal: widget.allowDecimals),
                        textAlign: TextAlign.center,
                        cursorColor: AppColors.brandPrimary,
                        cursorWidth: 1.5,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: widget.size.fontSize,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                        onChanged: _handleTypingChange,
                        onSubmitted: (_) => _submitDirectInput(),
                      ),
                    )
                  else
                    Text(
                      _formatValue(widget.value),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: widget.size.fontSize,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  if (widget.unit != null) ...[
                    const SizedBox(width: 3),
                    Text(
                      widget.unit!,
                      style: TextStyle(
                        fontSize: widget.size.fontSize - 1,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Микро-кнопка [+] ──
          _MicroButton(
            icon: PhosphorIconsBold.plus,
            size: widget.size,
            onTap: _handleIncrement,
          ),
        ],
      ),
    );
  }
}

class _MicroButton extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final AppStepperSize size;
  final VoidCallback onTap;

  const _MicroButton({
    required this.icon,
    this.iconColor,
    required this.size,
    required this.onTap,
  });

  @override
  State<_MicroButton> createState() => _MicroButtonState();
}

class _MicroButtonState extends State<_MicroButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final defaultBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final hoverBg = AppColors.brandPrimary.withValues(alpha: 0.15);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fastDuration,
          width: widget.size.btnSize,
          height: widget.size.btnSize,
          decoration: BoxDecoration(
            color: _isHovered ? hoverBg : defaultBg,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: widget.size.iconSize,
            color: widget.iconColor ?? (_isHovered ? AppColors.brandPrimary : defaultColor),
          ),
        ),
      ),
    );
  }
}
