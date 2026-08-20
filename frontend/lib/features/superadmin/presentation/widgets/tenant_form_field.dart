import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class TenantFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool isRequired;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const TenantFormField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.isRequired = true,
    this.hint,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: AppTextStyles.body.copyWith(
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        hintStyle: AppTextStyles.caption.copyWith(
          color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext).withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, color: AppColors.brandPrimary, size: 18),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator ?? (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return 'Обязательное поле';
        }
        return null;
      },
    );
  }
}
