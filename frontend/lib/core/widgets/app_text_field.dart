import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isDense;
  final bool autofocus;
  final bool readOnly;
  final bool isCompact;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? errorText;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.isDense = true,
    this.autofocus = false,
    this.readOnly = false,
    this.isCompact = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: isCompact ? 38 : 46,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onTap: onTap,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: isCompact ? 13 : 14,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: bg,
              hintText: hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                fontSize: isCompact ? 13 : 14,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isCompact ? 8 : 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.danger),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
