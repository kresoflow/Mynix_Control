// ==============================================================================
// МОДУЛЬ: Склад / Автокомплит номенклатуры приходной накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
import 'receipt_row_data.dart';
import 'receive_document_row_callbacks.dart';

// ─── 1. Поле автокомплита номенклатуры со стабильным OverlayEntry ────────────

/// [UI-KIT] [ИНВАРИАНТ] Поле ввода номенклатуры с выпадающим списком позиций.
/// Реализовано на базе прямого `OverlayEntry`, исключая баги Flutter `OverlayPortalController.hide()`.
class ReceiveDocumentAutocompleteField extends StatefulWidget {
  final ReceiptRowData item;
  final int index;
  final List<ReceiptRowData> items;
  final List<Ingredient> availableIngredients;
  final int tabIndex;
  final bool isDark;
  final ValueChanged<Ingredient> onIngredientSelected;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNameSubmitted;

  const ReceiveDocumentAutocompleteField({
    super.key,
    required this.item,
    required this.index,
    required this.items,
    required this.availableIngredients,
    required this.tabIndex,
    required this.isDark,
    required this.onIngredientSelected,
    required this.onNameChanged,
    required this.onNameSubmitted,
  });

  @override
  State<ReceiveDocumentAutocompleteField> createState() => _ReceiveDocumentAutocompleteFieldState();
}

class _ReceiveDocumentAutocompleteFieldState extends State<ReceiveDocumentAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    widget.item.nameFocusNode.addListener(_handleFocusOrTextChanged);
    widget.item.nameController.addListener(_handleFocusOrTextChanged);
  }

  @override
  void didUpdateWidget(ReceiveDocumentAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      oldWidget.item.nameFocusNode.removeListener(_handleFocusOrTextChanged);
      oldWidget.item.nameController.removeListener(_handleFocusOrTextChanged);
      widget.item.nameFocusNode.addListener(_handleFocusOrTextChanged);
      widget.item.nameController.addListener(_handleFocusOrTextChanged);
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
    widget.item.nameFocusNode.removeListener(_handleFocusOrTextChanged);
    widget.item.nameController.removeListener(_handleFocusOrTextChanged);
    super.dispose();
  }

  void _handleFocusOrTextChanged() {
    if (!mounted) return;
    final hasFocus = widget.item.nameFocusNode.hasFocus;
    final text = widget.item.nameController.text.trim();

    if (hasFocus && text.isNotEmpty && widget.item.ingredient == null) {
      _dismissTimer?.cancel();
      _showOverlay();
    } else if (!hasFocus) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted && !widget.item.nameFocusNode.hasFocus) _removeOverlay();
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
    final q = query.toLowerCase();
    return widget.availableIngredients.where((opt) {
      if (opt.isArchived || !opt.name.toLowerCase().contains(q)) return false;
      final isRetail = opt.attributes?['is_retail'] == true;
      return widget.tabIndex == 1 ? isRetail : (widget.tabIndex == 2 ? !isRetail : true);
    }).toList();
  }

  void _showOverlay() {
    if (!mounted || widget.item.ingredient != null) { _removeOverlay(); return; }
    final filtered = _filterIngredients(widget.item.nameController.text);
    if (filtered.isEmpty) { _removeOverlay(); return; }
    if (_overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) _overlayEntry!.markNeedsBuild();
      });
      return;
    }
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final currentFiltered = _filterIngredients(widget.item.nameController.text);
        if (currentFiltered.isEmpty) return const SizedBox.shrink();

        return Positioned(
          width: 360,
          child: CompositedTransformFollower(
            link: _layerLink, showWhenUnlinked: false, offset: const Offset(0, 42),
            child: TapRegion(
              groupId: widget.item,
              child: ReceiveDocumentAutocompleteOptionsView(
                options: currentFiltered,
                onSelected: (selection) {
                  _dismissTimer?.cancel();
                  _removeOverlay();
                  widget.onIngredientSelected(selection);
                },
              ),
            ),
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  KeyEventResult _handleRowKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape && _overlayEntry != null) {
      _dismissTimer?.cancel();
      _removeOverlay();
      return KeyEventResult.handled;
    }
    return ReceiveDocumentRowCallbacks.handleArrowKeyNavigation(
      event: event, items: widget.items, index: widget.index, targetNode: (r) => r.nameFocusNode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.tabIndex == 2 ? 5 : 3,
      child: SizedBox(
        height: 40,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: TapRegion(
            groupId: widget.item,
            child: Focus(
              onKeyEvent: _handleRowKeyEvent,
              child: TextFormField(
                controller: widget.item.nameController,
                focusNode: widget.item.nameFocusNode,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 13, fontWeight: FontWeight.w500,
                ),
                decoration: buildBulkInputDecoration(
                  context, 'Поиск номенклатуры...', isHintOnly: true,
                  suffixIcon: widget.item.ingredient != null
                      ? const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.success, size: 16,)
                      : Icon(PhosphorIconsRegular.magnifyingGlass, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 16,),
                ),
                onChanged: widget.onNameChanged,
                onFieldSubmitted: (_) {
                  _dismissTimer?.cancel();
                  _removeOverlay();
                  widget.onNameSubmitted();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 2. Выпадающее меню с результатами поиска ────────────────────────────────

/// [UI-KIT] Выпадающее меню с результатами поиска для автокомплита.
class ReceiveDocumentAutocompleteOptionsView extends StatelessWidget {
  final Iterable<Ingredient> options;
  final ValueChanged<Ingredient> onSelected;

  const ReceiveDocumentAutocompleteOptionsView({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8, borderRadius: AppRadii.inputRadius,
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: Container(
          width: 360, constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            borderRadius: AppRadii.inputRadius,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
            itemBuilder: (context, optIndex) {
              final option = options.elementAt(optIndex);
              final isDeficit = option.currentStock < 0;

              return ListTile(
                dense: true,
                title: Text(option.name, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Закупка: ${option.costPerUnit.toCurrency(context)}', style: AppTextStyles.caption.copyWith(color: subtextColor, fontSize: 11)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(UnitFormatter.formatAmount(option.currentStock, option.unit,), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDeficit ? AppColors.danger : textColor)),
                    Text(isDeficit ? 'дефицит' : 'на складе', style: TextStyle(fontSize: 10, fontWeight: isDeficit ? FontWeight.w600 : FontWeight.normal, color: isDeficit ? AppColors.danger : subtextColor)),
                  ],
                ),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }
}
