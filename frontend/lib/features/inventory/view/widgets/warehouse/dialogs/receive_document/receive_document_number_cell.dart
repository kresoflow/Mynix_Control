import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';

class ReceiveDocumentNumberCell extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontSize: 13,
          ),
          decoration: buildBulkInputDecoration(context, hint),
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmitted(),
        ),
      ),
    );
  }
}
