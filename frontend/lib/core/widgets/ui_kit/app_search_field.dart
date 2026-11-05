// ==============================================================================
// Title: AppSearchField (UI Kit Search Field)
// Path: frontend/lib/core/widgets/ui_kit/app_search_field.dart
// Description: Поле поиска Design System с поддержкой хоткеев и изоляции экрана.
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kreso_frontend/core/router/app_route_observer.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_save_shortcut_scope.dart';
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
  final bool isPrimary;
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
  final bool enableDebounce;
  final Duration debounceDuration;

  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Поиск...',
    this.shortcutHint,
    this.isPrimary = true,
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
    this.enableDebounce = true,
    this.debounceDuration = const Duration(milliseconds: 250),
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  static KeyEvent? _lastHandledKeyEvent;
  static _AppSearchFieldState? _activeFocusedInstance;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
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

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _activeFocusedInstance = this;
        } else if (_activeFocusedInstance == this) {
          _activeFocusedInstance = null;
        }
      });
    }
  }

  void _onTextChanged(String val) {
    if (!widget.enableDebounce || widget.debounceDuration == Duration.zero) {
      widget.onChanged?.call(val);
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        widget.onChanged?.call(val);
      }
    });
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitiallyExpanded != oldWidget.isInitiallyExpanded) {
      if (widget.mode == AppSearchMode.collapsible && _isExpanded != widget.isInitiallyExpanded) {
        setState(() {
          _isExpanded = widget.isInitiallyExpanded;
        });
      }
    }
  }

  void _focusAndPositionCursor() {
    _focusNode.requestFocus();
    if (_controller.text.isNotEmpty) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _controller.selection = const TextSelection.collapsed(offset: 0);
    }
  }

  // [ИНВАРИАНТ] Проверка видимости и активности текущего поля поиска.
  // Исключает перехват фокуса полями на скрытых экранах (IndexedStack) и неактивных вкладках (TabBarView).
  bool _isActiveAndVisible() {
    if (!mounted) return false;

    // 1. Модальные окна: если поверх открыт другой Route/Dialog,
    // фоновый поиск не должен перехватывать горячие клавиши.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null && !modalRoute.isCurrent) {
      return false;
    }

    // 1.1. Абсолютная изоляция модальных окон (AppSaveShortcutScope / AppRouteObserver / rootNav):
    // Если открыт модальный диалог, а текущий поиск находится на фоновом экране (не в PopupRoute),
    // фоновый поиск полностью блокируется и не реагирует на хоткеи!
    final isAnyModalPresent = AppSaveShortcutScope.isAnyModalOpen || AppRouteObserver.isModalOpen;
    if (isAnyModalPresent && (modalRoute == null || modalRoute is! PopupRoute)) {
      return false;
    }

    // 1.2. Изоляция веток StatefulShellRoute от корневых диалогов (rootNavigator):
    // Если поиск находится во вложенном навигаторе ветки, а на корневом навигаторе
    // открыт диалог/модалка (rootNav.canPop() == true), фоновый поиск полностью блокируется.
    final rootNav = Navigator.maybeOf(context, rootNavigator: true);
    if (rootNav != null && modalRoute != null && modalRoute.navigator != rootNav) {
      if (rootNav.canPop()) {
        return false;
      }
    }

    // 2. Изоляция веток IndexedStack (проверяем Visibility в дереве предков)
    if (!Visibility.of(context)) {
      return false;
    }

    // 3. Изоляция скрытых веток TickerMode
    if (!TickerMode.valuesOf(context).enabled) {
      return false;
    }

    // 4. RenderObject: проверяем, что виджет смонтирован и имеет размеры.
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
      return false;
    }
    if (renderObject.size.isEmpty) return false;

    // 5. Точная проверка экранных координат через localToGlobal:
    // В TabBarView / PageView неактивные вкладки возвращают NaN или координаты за пределами экрана.
    try {
      final pos = renderObject.localToGlobal(Offset.zero);
      if (pos.dx.isNaN || pos.dy.isNaN) {
        return false;
      }
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        final fieldRect = Rect.fromLTWH(
          pos.dx,
          pos.dy,
          renderObject.size.width,
          renderObject.size.height,
        );
        final viewportRect = Rect.fromLTWH(
          0,
          0,
          mediaQuery.size.width,
          mediaQuery.size.height,
        );
        if (!viewportRect.overlaps(fieldRect)) {
          return false;
        }
      }
    } catch (_) {
      return false;
    }

    return true;
  }

  // ── 2. Обработка локальных хоткеев (Ctrl+F, Cmd+K, F2, Esc) ───────────────
  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!widget.enableHotkeys || !mounted) return false;
    if (event is! KeyDownEvent) return false;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.controlRight) ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.metaLeft) ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.metaRight);

    // [ИНВАРИАНТ] physicalKey гарантирует срабатывание в русской раскладке (клавиша 'А')
    final isKeyF = event.physicalKey == PhysicalKeyboardKey.keyF ||
        event.logicalKey == LogicalKeyboardKey.keyF;
    final isKeyK = event.physicalKey == PhysicalKeyboardKey.keyK ||
        event.logicalKey == LogicalKeyboardKey.keyK;
    final isF2 = event.physicalKey == PhysicalKeyboardKey.f2 ||
        event.logicalKey == LogicalKeyboardKey.f2;

    // Ctrl+F / Cmd+K / F2: открыть и сфокусировать поиск именно в текущем видимом разделе
    if ((isCtrlOrCmd && (isKeyF || isKeyK)) || isF2) {
      if (!widget.isPrimary) return false;

      // Игнорируем невидимые или неактивные инпуты на фоновых экранах/вкладках
      if (!_isActiveAndVisible()) {
        return false;
      }

      // Предотвращаем гонку, если на одном экране смонтировано несколько поисковых полей
      if (identical(_lastHandledKeyEvent, event)) {
        return true;
      }
      _lastHandledKeyEvent = event;

      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
          widget.onExpandedChanged?.call(true);
        });
      }
      _focusAndPositionCursor();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusAndPositionCursor();
        }
      });
      return true;
    }

    // Escape для развёрнутого collapsible-поиска, даже если курсор кликнули вне поля (в таблицу)
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.physicalKey == PhysicalKeyboardKey.escape) {
      if (widget.mode == AppSearchMode.collapsible && _isExpanded) {
        if (_activeFocusedInstance != null && _activeFocusedInstance != this) {
          return false;
        }

        if (!_isActiveAndVisible()) return false;

        if (identical(_lastHandledKeyEvent, event)) {
          return true;
        }
        _lastHandledKeyEvent = event;

        _debounceTimer?.cancel();

        // Фаза 1: Если в поле есть текст — очищаем текст и сбрасываем фильтр
        if (_controller.text.isNotEmpty) {
          _controller.clear();
          widget.onChanged?.call('');
          widget.onClear?.call();
          return true;
        }

        // Фаза 2: Поле пустое — сворачиваем его
        setState(() {
          _isExpanded = false;
          widget.onExpandedChanged?.call(false);
          widget.onCollapsed?.call();
        });
        _focusNode.unfocus();
        return true;
      }
    }

    return false;
  }

  // ── 3. Локальный перехват Escape в дереве фокуса (Desktop Standard) ────────
  KeyEventResult _handleFocusKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.physicalKey == PhysicalKeyboardKey.escape) {
      if (identical(_lastHandledKeyEvent, event)) {
        return KeyEventResult.handled;
      }
      _lastHandledKeyEvent = event;

      _debounceTimer?.cancel();

      // Фаза 1: Если в поле есть введённый текст — очищаем только текст, сохраняя фокус
      if (_controller.text.isNotEmpty) {
        _controller.clear();
        widget.onChanged?.call('');
        widget.onClear?.call();
        _focusNode.requestFocus();
        return KeyEventResult.handled;
      }

      // Фаза 2: Если поле уже пустое — снимаем фокус и сворачиваем (если collapsible)
      _focusNode.unfocus();
      if (widget.mode == AppSearchMode.collapsible && _isExpanded) {
        setState(() {
          _isExpanded = false;
          widget.onExpandedChanged?.call(false);
          widget.onCollapsed?.call();
        });
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    if (_activeFocusedInstance == this) {
      _activeFocusedInstance = null;
    }
    _debounceTimer?.cancel();
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
        _focusAndPositionCursor();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusAndPositionCursor();
          }
        });
      } else {
        _debounceTimer?.cancel();
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
                      child: Focus(
                        onKeyEvent: _handleFocusKeyEvent,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: widget.autoFocus || (widget.mode == AppSearchMode.collapsible),
                          onChanged: _onTextChanged,
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
                        _debounceTimer?.cancel();
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
                ] else if (widget.shortcutHint != null && _controller.text.isEmpty) ...[
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
