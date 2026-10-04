// ==============================================================================
// МОДУЛЬ: Склад / Ячейка выбора единицы измерения
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';

/// Выпадающий список выбора единицы измерения в строке приходной накладной.
/// Оформлен в едином стиле ячеек Bulk Add.
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
    final effectiveUnit = (UnitFormatter.orderedUiSymbols.contains(selectedUnit) || selectedUnit == 'порц')
        ? selectedUnit
        : 'шт';

    return Container(
      width: 85,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveUnit,
          isExpanded: true,
          icon: Icon(
            PhosphorIconsRegular.caretDown,
            size: 14,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: [
            ...UnitFormatter.uiDropdownItems,
            if (selectedUnit == 'порц')
              const DropdownMenuItem(value: 'порц', child: Text('порц')),
          ],
          onChanged: onUnitChanged,
        ),
      ),
    );
  }
}
