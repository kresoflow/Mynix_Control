import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Размеры поля поиска
enum AppSearchFieldSize {
  sm, // 32px — для узких сайдбаров и вложенных колонок
  md, // 36px — стандарт для главных тулбаров и таблиц
  lg, // 44px — для модальных окон и сенсорного POS
}

/// Режим отображения поиска
enum AppSearchMode {
  standard,    // Всегда видимое поле ввода
  collapsible, // Свернутая иконка, раскрывающаяся по клику
}

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final String? shortcutHint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onCollapsed;
  final double? width;
  final AppSearchFieldSize size;
  final AppSearchMode mode;
  final bool autoFocus;
  final bool isInitiallyExpanded;

  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Поиск...',
    this.shortcutHint = 'Ctrl+F',
    this.onChanged,
    this.onClear,
    this.onCollapsed,
    this.width,
    this.size = AppSearchFieldSize.md,
    this.mode = AppSearchMode.standard,
    this.autoFocus = false,
    this.isInitiallyExpanded = false,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;
  bool _isExpanded = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
    }

    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }

    _isExpanded = widget.mode == AppSearchMode.standard || widget.isInitiallyExpanded;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_isInternalController) {
      _controller.dispose();
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _focusNode.requestFocus();
      } else {
        _controller.clear();
        widget.onChanged?.call('');
        widget.onCollapsed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Метрики размеров
    final double height;
    final double fontSize;
    final double iconSize;
    final double badgeFontSize;

    switch (widget.size) {
      case AppSearchFieldSize.sm:
        height = 32.0;
        fontSize = 12.0;
        iconSize = 14.0;
        badgeFontSize = 9.5;
        break;
      case AppSearchFieldSize.md:
        height = 36.0;
        fontSize = 13.0;
        iconSize = 16.0;
        badgeFontSize = 10.0;
        break;
      case AppSearchFieldSize.lg:
        height = 44.0;
        fontSize = 14.5;
        iconSize = 18.0;
        badgeFontSize = 11.0;
        break;
    }

    // Режим свернутой кнопки
    if (widget.mode == AppSearchMode.collapsible && !_isExpanded) {
      return Tooltip(
        message: widget.shortcutHint != null
            ? '${widget.hintText} (${widget.shortcutHint})'
            : widget.hintText,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            width: height,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: iconSize,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ),
      );
    }

    final borderColor = _isFocused
        ? AppColors.brandPrimary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: widget.width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: borderColor,
          width: _isFocused ? 1.2 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.18 : 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;

          return Row(
            children: [
              const SizedBox(width: 10),
              Icon(
                PhosphorIconsRegular.magnifyingGlass,
                size: iconSize,
                color: _isFocused
                    ? AppColors.brandPrimary
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus || (widget.mode == AppSearchMode.collapsible),
                  onChanged: widget.onChanged,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontSize: fontSize,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hintText,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      fontSize: fontSize,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              if (hasText)
                InkWell(
                  onTap: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                    widget.onClear?.call();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(
                      PhosphorIconsRegular.x,
                      size: iconSize - 2,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                )
              else if (widget.shortcutHint != null && !_isFocused)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.shortcutHint!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ),
                ),
              if (widget.mode == AppSearchMode.collapsible) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(
                      PhosphorIconsRegular.xCircle,
                      size: iconSize,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          );
        },
      ),
    );
  }
}
