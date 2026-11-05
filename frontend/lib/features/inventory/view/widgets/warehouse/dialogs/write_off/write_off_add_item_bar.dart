// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

// ==============================================================================
// 2. СТРОКА БЫСТРОГО ПОИСКА И ДОБАВЛЕНИЯ ПОЗИЦИЙ
// ==============================================================================
/// [ИНВАРИАНТ] Поиск товаров/сырья со стабильным выпадающим списком на OverlayEntry.
class WriteOffAddItemBar extends StatefulWidget {
  final List<Ingredient> availableIngredients;
  final ValueChanged<Ingredient> onIngredientSelected;
  final FocusNode? focusNode;
  final bool autoFocus;

  const WriteOffAddItemBar({
    super.key,
    required this.availableIngredients,
    required this.onIngredientSelected,
    this.focusNode,
    this.autoFocus = false,
  });

  @override
  State<WriteOffAddItemBar> createState() => _WriteOffAddItemBarState();
}

class _WriteOffAddItemBarState extends State<WriteOffAddItemBar> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _textController = TextEditingController();
  final Object _tapRegionGroup = Object();
  FocusNode? _internalFocusNode;
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusOrTextChanged);
    _textController.addListener(_handleFocusOrTextChanged);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_effectiveFocusNode.hasFocus) _effectiveFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(WriteOffAddItemBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusOrTextChanged);
      _effectiveFocusNode.addListener(_handleFocusOrTextChanged);
    }
    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) _overlayEntry!.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeOverlay();
    _effectiveFocusNode.removeListener(_handleFocusOrTextChanged);
    _textController.removeListener(_handleFocusOrTextChanged);
    _textController.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusOrTextChanged() {
    if (!mounted) return;
    final hasFocus = _effectiveFocusNode.hasFocus;
    final text = _textController.text.trim();

    if (hasFocus && text.isNotEmpty) {
      _dismissTimer?.cancel();
      _showOverlay();
    } else if (!hasFocus) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted && !_effectiveFocusNode.hasFocus) _removeOverlay();
      });
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<Ingredient> _filterIngredients(String query) {
    if (query.isEmpty) return const [];
    final q = query.toLowerCase().trim();
    return widget.availableIngredients.where((i) => !i.isArchived && i.name.toLowerCase().contains(q)).toList();
  }

  void _showOverlay() {
    if (!mounted) return;
    final options = _filterIngredients(_textController.text);
    if (options.isEmpty) { _removeOverlay(); return; }
    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) _overlayEntry!.markNeedsBuild();
      });
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final currentOptions = _filterIngredients(_textController.text);
        if (currentOptions.isEmpty) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Positioned(
          width: 580,
          child: CompositedTransformFollower(
            link: _layerLink, showWhenUnlinked: false, offset: const Offset(0, 48),
            child: TapRegion(
              groupId: _tapRegionGroup,
              child: Material(
                elevation: 8, borderRadius: AppRadii.inputRadius,
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.inputRadius,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4), shrinkWrap: true,
                    itemCount: currentOptions.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    itemBuilder: (context, index) {
                      final item = currentOptions[index];
                      final isRetail = item.attributes?['is_retail'] == true;
                      final hasStock = item.currentStock > 0.001;

                      return ListTile(
                        dense: true,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(item.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: hasStock ? AppColors.success.withValues(alpha: isDark ? 0.16 : 0.10) : AppColors.danger.withValues(alpha: isDark ? 0.16 : 0.10),
                                borderRadius: AppRadii.radiusXs,
                              ),
                              child: Text('В наличии: ${UnitFormatter.formatAmount(item.currentStock, item.unit)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: hasStock ? AppColors.success : AppColors.danger)),
                            ),
                            const SizedBox(width: 8),
                            Text(isRetail ? 'Витрина' : 'Сырье', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                          ],
                        ),
                        onTap: () {
                          _dismissTimer?.cancel();
                          widget.onIngredientSelected(item);
                          _textController.clear();
                          _removeOverlay();
                          _effectiveFocusNode.requestFocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape && _overlayEntry != null) {
      _dismissTimer?.cancel();
      _removeOverlay();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TapRegion(
        groupId: _tapRegionGroup,
        child: Focus(
          onKeyEvent: _handleKeyEvent,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, _) {
              final hasText = value.text.isNotEmpty;
              return TextField(
                controller: _textController,
                focusNode: _effectiveFocusNode,
                style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText),
                decoration: InputDecoration(
                  hintText: 'Поиск номенклатуры для списания (сырье, товары)...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
                  suffixIcon: hasText
                      ? IconButton(
                          icon: const Icon(PhosphorIconsRegular.x, size: 16),
                          onPressed: () {
                            _textController.clear();
                            _removeOverlay();
                            _effectiveFocusNode.requestFocus();
                          },
                        )
                      : null,
                  isDense: true, filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(borderRadius: AppRadii.inputRadius, borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppRadii.inputRadius, borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: AppRadii.inputRadius, borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
