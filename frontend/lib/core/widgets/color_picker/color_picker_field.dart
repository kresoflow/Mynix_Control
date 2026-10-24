import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'color_picker_utils.dart';
import 'app_color_picker_dialog.dart';

class ColorPickerField extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String?> onColorSelected;

  const ColorPickerField({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsedColor = ColorPickerUtils.parseHex(selectedColor);
    final hasColor = parsedColor != null;

    return InkWell(
      onTap: () async {
        final result = await AppColorPickerDialog.show(context, initialHex: selectedColor);
        if (result != null) {
          onColorSelected(result.isEmpty ? null : result);
        }
      },
      borderRadius: AppRadii.inputRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : AppColors.lightBg,
          borderRadius: AppRadii.inputRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: parsedColor ?? AppColors.brandPrimary,
                borderRadius: AppRadii.radiusSm,
                border: Border.all(
                  color: AppColors.pureWhite.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: hasColor
                    ? AppShadows.dotGlow(parsedColor, opacity: 0.35, blur: 6)
                    : null,
              ),
              child: !hasColor
                  ? const Icon(PhosphorIconsRegular.palette, size: 14, color: AppColors.pureWhite)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Цвет карточки (Photoshop)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasColor ? ColorPickerUtils.toHex(parsedColor) : 'По умолчанию (из темы)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasColor ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ],
        ),
      ),
    );
  }
}
