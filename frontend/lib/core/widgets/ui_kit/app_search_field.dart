import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Размеры поля поиска
enum AppSearchFieldSize {
  sm, // 34px — для узких сайдбаров и вложенных колонок
  md, // 38px — стандарт для главных тулбаров и таблиц
  lg, // 46px — для модальных окон и сенсорного POS
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
  bool _isHovered = false;

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
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_isInternalController) _controller.dispose();
    if (_isInternalFocusNode) _focusNode.dispose();
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

    final double height;
    final double fontSize;
    final double iconSize;
    final double leftPadding;
    final double iconGap;
    final double rightPadding;
    final double actionSize;
    final double badgeFontSize;

    switch (widget.size) {
      case AppSearchFieldSize.sm:
        height = 34.0;
        fontSize = 12.0;
        iconSize = 14.0;
        leftPadding = 10.0;
        iconGap = 8.0;
        actionSize = 20.0;
        rightPadding = 7.0;
        badgeFontSize = 9.5;
        break;
      case AppSearchFieldSize.md:
        height = 38.0;
        fontSize = 13.0;
        iconSize = 16.0;
        leftPadding = 12.0;
        iconGap = 8.0;
        actionSize = 24.0;
        rightPadding = 8.0;
        badgeFontSize = 10.5;
        break;
      case AppSearchFieldSize.lg:
        height = 46.0;
        fontSize = 14.5;
        iconSize = 18.0;
        leftPadding = 14.0;
        iconGap = 10.0;
        actionSize = 28.0;
        rightPadding = 9.0;
        badgeFontSize = 11.5;
        break;
    }

    // Режим свернутой кнопки
    if (widget.mode == AppSearchMode.collapsible && !_isExpanded) {
      return Tooltip(
        message: widget.shortcutHint != null
            ? '${widget.hintText} (${widget.shortcutHint})'
            : widget.hintText,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
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
                  width: 1.0,
                ),
              ),
              child: Icon(
                PhosphorIconsRegular.magnifyingGlass,
                size: iconSize,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
        ),
      );
    }

    final Color bgColor = _isFocused
        ? (isDark ? AppColors.darkCard : AppColors.lightCard)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);

    final Color borderColor = _isFocused
        ? AppColors.brandPrimary
        : (_isHovered
            ? (isDark ? AppColors.brandPrimary.withValues(alpha: 0.6) : AppColors.brandPrimary.withValues(alpha: 0.5))
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder));

    final Color subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final Color textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: widget.width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius: 6,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: leftPadding),
                Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: iconSize,
                  color: _isFocused ? AppColors.brandPrimary : subtextColor,
                ),
                SizedBox(width: iconGap),
                Expanded(
                  child: Center(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: widget.autoFocus || (widget.mode == AppSearchMode.collapsible),
                      onChanged: widget.onChanged,
                      textAlignVertical: TextAlignVertical.center,
                      cursorHeight: fontSize * 1.15,
                      cursorWidth: 1.6,
                      cursorColor: AppColors.brandPrimary,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textColor,
                        fontSize: fontSize,
                        height: 1.0,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hintText,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: subtextColor,
                          fontSize: fontSize,
                          height: 1.0,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                        filled: false,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                if (hasText) ...[
                  _buildActionBtn(
                    icon: PhosphorIconsRegular.x,
                    size: actionSize,
                    iconSize: iconSize - 2,
                    tooltip: 'Очистить',
                    color: subtextColor,
                    onTap: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                      widget.onClear?.call();
                    },
                  ),
                  SizedBox(width: rightPadding),
                ] else if (widget.mode == AppSearchMode.collapsible) ...[
                  _buildActionBtn(
                    icon: PhosphorIconsRegular.x,
                    size: actionSize,
                    iconSize: iconSize - 2,
                    tooltip: 'Закрыть (Esc)',
                    color: subtextColor,
                    onTap: _toggleExpanded,
                  ),
                  SizedBox(width: rightPadding),
                ] else if (widget.shortcutHint != null && !_isFocused) ...[
                  Container(
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
                        color: subtextColor,
                      ),
                    ),
                  ),
                  SizedBox(width: rightPadding + 2),
                ] else ...[
                  SizedBox(width: leftPadding),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required double size,
    required double iconSize,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.max),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
