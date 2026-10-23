// ==============================================================================
// МОДУЛЬ: Склад / Поле ввода суммы частичной оплаты
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// Поле ввода суммы частичной оплаты.
/// Оформлено в стиле AppSearchField: иконка слева, чистый контур с фокусом,
/// подсветка акцентным цветом и кнопка очистки/валюты справа.
class ReceiveDocumentAmountField extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;

  const ReceiveDocumentAmountField({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  State<ReceiveDocumentAmountField> createState() => _ReceiveDocumentAmountFieldState();
}

class _ReceiveDocumentAmountFieldState extends State<ReceiveDocumentAmountField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final subtextColor = widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final textColor = widget.isDark ? AppColors.darkText : AppColors.lightText;
    final iconColor = _isFocused ? AppColors.brandPrimary : subtextColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 135,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          // [ИНВАРИАНТ] Бесшовный стиль без ободка (border: null):
          // встраивается в панель способов оплаты без визуального шума
          color: widget.isDark
              ? (_isHovered || _isFocused
                  ? AppColors.darkSurface
                  : AppColors.darkSurface.withValues(alpha: 0.5))
              : (_isHovered || _isFocused
                  ? AppColors.lightBg
                  : AppColors.lightBg.withValues(alpha: 0.7)),
          borderRadius: AppRadii.inputRadius,
        ),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Иконка слева
            Icon(
              PhosphorIconsRegular.coins,
              size: 14,
              color: iconColor,
            ),
            const SizedBox(width: 6),

            // Поле ввода суммы
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Сумма...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    color: subtextColor.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // Кнопка очистки или валютный знак
            if (hasText)
              InkWell(
                onTap: () {
                  widget.controller.clear();
                  _focusNode.requestFocus();
                },
                borderRadius: AppRadii.inputRadius,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    PhosphorIconsRegular.x,
                    size: 12,
                    color: subtextColor,
                  ),
                ),
              )
            else
              Text(
                'с',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: subtextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
