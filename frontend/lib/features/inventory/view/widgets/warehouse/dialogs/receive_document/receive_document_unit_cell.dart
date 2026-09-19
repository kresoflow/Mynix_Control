import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class ReceiveDocumentUnitCell extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final bool isDark;

  const ReceiveDocumentUnitCell({
    super.key,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: const ['шт', 'л', 'мл', 'кг', 'г', 'порц'].contains(selectedUnit)
              ? selectedUnit
              : 'шт',
          isExpanded: true,
          icon: const Icon(PhosphorIconsRegular.caretDown, size: 14),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontSize: 13,
          ),
          items: const ['шт', 'л', 'мл', 'кг', 'г', 'порц'].map((u) {
            return DropdownMenuItem(value: u, child: Text(u));
          }).toList(),
          onChanged: onUnitChanged,
        ),
      ),
    );
  }
}
