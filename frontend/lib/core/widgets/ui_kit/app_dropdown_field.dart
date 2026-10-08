// ==============================================================================
// УНИФИЦИРОВАННЫЙ ВЫПАДАЮЩИЙ СПИСОК (APP DROPDOWN FIELD)
// ==============================================================================
//
// [ИНВАРИАНТ] Никаких сырых DropdownButtonFormField с разнородными рамками.
// Полная поддержка токенов темы (Ocean, Cream, Ember) и единого инпут-стиля.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

/// [UI-KIT] Стандартизированный выпадающий список выбора
class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final bool isCompact;
  final String? errorText;
  final FormFieldValidator<T>? validator;
  final bool disabled;
  final double? menuMaxHeight;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.isCompact = false,
    this.errorText,
    this.validator,
    this.disabled = false,
    this.menuMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final dropdownBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final inputRadius = BorderRadius.circular(AppRadii.input);

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
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: disabled ? null : onChanged,
            validator: validator,
            dropdownColor: dropdownBg,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            menuMaxHeight: menuMaxHeight ?? (items.length <= 5 ? (items.length * 48.0) : 240.0),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: isCompact ? 13 : 14,
            ),
            icon: Icon(
              PhosphorIconsRegular.caretDown,
              size: 16,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: disabled ? bg.withValues(alpha: 0.5) : bg,
              hintText: hintText,
              hintStyle: AppTextStyles.caption.copyWith(
                color: isDark
                    ? AppColors.darkSubtext.withValues(alpha: 0.6)
                    : AppColors.lightSubtext.withValues(alpha: 0.6),
                fontSize: isCompact ? 13 : 14,
              ),
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 20,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isCompact ? 8 : 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: inputRadius,
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: inputRadius,
                borderSide: BorderSide(
                  color: AppColors.brandPrimary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: inputRadius,
                borderSide: const BorderSide(color: AppColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: inputRadius,
                borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: inputRadius,
                borderSide: BorderSide(
                  color: borderColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.danger,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
