import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

InputDecoration buildBulkInputDecoration(BuildContext context, String label) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
  final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

  return InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.caption.copyWith(
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      fontSize: 13,
    ),
    filled: true,
    fillColor: bg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  );
}
