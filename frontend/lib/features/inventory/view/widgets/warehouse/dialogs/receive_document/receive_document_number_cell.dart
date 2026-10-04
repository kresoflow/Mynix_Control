// ==============================================================================
// МОДУЛЬ: Склад / Числовая ячейка строки накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';

/// Числовое поле ввода строки приходной накладной (количество, алерт, цена).
/// Использует общий стиль оформления ячеек Bulk Add без плавающих меток.
class ReceiveDocumentNumberCell extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final TextAlign textAlign;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final FocusOnKeyEventCallback onKeyEvent;
  final bool isDark;

  const ReceiveDocumentNumberCell({
    super.key,
    required this.width,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.textAlign = TextAlign.start,
    required this.onChanged,
    required this.onSubmitted,
    required this.onKeyEvent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: Focus(
        onKeyEvent: onKeyEvent,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          textAlign: textAlign,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: buildBulkInputDecoration(
            context,
            hint,
            isHintOnly: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmitted(),
        ),
      ),
    );
  }
}
