import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ValueChanged<bool>? onExpandedChanged;
  final double? width;
  final AppSearchFieldSize size;
  final AppSearchMode mode;
  final bool autoFocus;
  final bool isInitiallyExpanded;
  final bool enableHotkeys;

  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Поиск...',
    this.shortcutHint = 'Ctrl+F',
    this.onChanged,
    this.onClear,
    this.onCollapsed,
    this.onExpandedChanged,
    this.width,
    this.size = AppSearchFieldSize.md,
    this.mode = AppSearchMode.standard,
    this.autoFocus = false,
    this.isInitiallyExpanded = false,
    this.enableHotkeys = true,
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

    if (widget.enableHotkeys) {
      HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!widget.enableHotkeys || !mounted) return false;
    if (event is! KeyDownEvent) return false;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Ctrl+F / Cmd+K / F2: открыть и сфокусировать поиск
    if ((isCtrlOrCmd && (event.logicalKey == LogicalKeyboardKey.keyF || event.logicalKey == LogicalKeyboardKey.keyK)) ||
        event.logicalKey == LogicalKeyboardKey.f2) {
      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
          widget.onExpandedChanged?.call(true);
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
      return true;
    }

    // Escape: очистить, расфокусировать и свернуть
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isFocused || (widget.mode == AppSearchMode.collapsible && _isExpanded)) {
        _controller.clear();
        widget.onChanged?.call('');
        widget.onClear?.call();
        _focusNode.unfocus();
        if (widget.mode == AppSearchMode.collapsible) {
          setState(() {
            _isExpanded = false;
            widget.onExpandedChanged?.call(false);
            widget.onCollapsed?.call();
          });
        }
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {
    if (widget.enableHotkeys) {
      HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    }
    _focusNode.removeListener(_onFocusChange);
    if (_isInternalController) _controller.dispose();
    if (_isInternalFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      widget.onExpandedChanged?.call(_isExpanded);
      if (_isExpanded) {
        _focusNode.requestFocus();
      } else {
        _controller.clear();
        widget.onChanged?.call('');
        widget.onClear?.call();
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
    final double opticalYOffset;

    switch (widget.size) {
      case AppSearchFieldSize.sm:
        height = 34.0;
        fontSize = 12.0;
        iconSize = 14.0;
        leftPadding = 10.0;
        iconGap = 8.0;
        actionSize = 20.0;
        rightPadding = 8.0;
        badgeFontSize = 9.5;
        opticalYOffset = -2.5;
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
        opticalYOffset = -3.5;
        break;
      case AppSearchFieldSize.lg:
        height = 46.0;
        fontSize = 14.5;
        iconSize = 18.0;
        leftPadding = 14.0;
        iconGap = 10.0;
        actionSize = 28.0;
        rightPadding = 10.0;
        badgeFontSize = 11.5;
        opticalYOffset = -4.5;
        break;
    }

    final Color subtextColor = isDark ? const Color(0xFF94A3B8) : AppColors.lightSubtext;
    final Color textColor = isDark ? Colors.white : AppColors.lightText;
    final Color iconColor = _isFocused ? AppColors.brandPrimary : subtextColor;

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
                color: iconColor,
              ),
            ),
          ),
        ),
      );
    }

    final Color bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    final Color borderColor = _isFocused
        ? AppColors.brandPrimary
        : (_isHovered
            ? (isDark ? AppColors.brandPrimary.withValues(alpha: 0.6) : AppColors.brandPrimary.withValues(alpha: 0.5))
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder));

    final double defaultWidth;
    switch (widget.size) {
      case AppSearchFieldSize.sm:
        defaultWidth = 220.0;
        break;
      case AppSearchFieldSize.md:
        defaultWidth = 260.0;
        break;
      case AppSearchFieldSize.lg:
        defaultWidth = 300.0;
        break;
    }

    final double? targetWidth = widget.width ?? (widget.mode == AppSearchMode.collapsible ? defaultWidth : null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double? effectiveWidth = targetWidth ?? (constraints.hasBoundedWidth ? null : defaultWidth);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: effectiveWidth,
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
                Center(
                  child: Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    size: iconSize,
                    color: iconColor,
                  ),
                ),
                SizedBox(width: iconGap),
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, opticalYOffset),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: widget.autoFocus || (widget.mode == AppSearchMode.collapsible),
                        onChanged: widget.onChanged,
                        textAlignVertical: TextAlignVertical.center,
                        cursorHeight: fontSize * 1.15,
                        cursorWidth: 1.6,
                        cursorColor: AppColors.brandPrimary,
                        strutStyle: StrutStyle(
                          fontSize: fontSize,
                          height: 1.0,
                          forceStrutHeight: true,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textColor,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          isCollapsed: true,
                          hintText: widget.hintText,
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: subtextColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasText) ...[
                  SizedBox(width: iconGap),
                  Center(
                    child: _buildActionBtn(
                      icon: PhosphorIconsRegular.x,
                      size: actionSize,
                      iconSize: iconSize - 2,
                      tooltip: 'Очистить',
                      color: subtextColor,
                      isDark: isDark,
                      onTap: () {
                        _controller.clear();
                        widget.onChanged?.call('');
                        widget.onClear?.call();
                      },
                    ),
                  ),
                  SizedBox(width: rightPadding),
                ] else if (widget.mode == AppSearchMode.collapsible) ...[
                  SizedBox(width: iconGap),
                  Center(
                    child: _buildActionBtn(
                      icon: PhosphorIconsRegular.x,
                      size: actionSize,
                      iconSize: iconSize - 2,
                      tooltip: 'Закрыть (Esc)',
                      color: subtextColor,
                      isDark: isDark,
                      onTap: _toggleExpanded,
                    ),
                  ),
                  SizedBox(width: rightPadding),
                ] else if (widget.shortcutHint != null && !_isFocused) ...[
                  SizedBox(width: iconGap),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.lightBorder,
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
                  ),
                  SizedBox(width: rightPadding),
                ] else ...[
                  SizedBox(width: leftPadding),
                ],
              ],
            );
          },
        ),
      ),
    );
      },
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required double size,
    required double iconSize,
    required String tooltip,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.max),
        hoverColor: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.lightBorder.withValues(alpha: 0.4),
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
