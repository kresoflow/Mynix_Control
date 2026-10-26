// ==============================================================================
// Title: SupplierPaymentMethodSelector
// Path: frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_payment_method_selector.dart
// Description: Селектор способа оплаты для модального окна взаиморасчетов.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

// ─── 1. Селектор способов оплаты взаиморасчета с поставщиком ──────────────────

/// [UI-KIT] Компонент выбора способа оплаты поставщику (наличные, банк, карта)
class SupplierPaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final bool isDark;

  const SupplierPaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.isDark,
  });

  static const List<(String, String, IconData)> _methods = [
    ('cash', 'Наличные', PhosphorIconsRegular.money),
    ('bank_transfer', 'Перевод / Р/С', PhosphorIconsRegular.bank),
    ('card', 'Карта', PhosphorIconsRegular.creditCard),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _methods.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _buildMethodChip(_methods[i].$1, _methods[i].$2, _methods[i].$3),
        ],
      ],
    );
  }

  Widget _buildMethodChip(String id, String label, IconData icon) {
    final isSelected = selectedMethod == id;
    final bg = isSelected
        ? AppColors.brandPrimary.withValues(alpha: 0.15)
        : (isDark ? AppColors.darkBg : AppColors.lightBg);
    final border = isSelected
        ? AppColors.brandPrimary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final iconColor = isSelected
        ? AppColors.brandPrimary
        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return Expanded(
      child: InkWell(
        onTap: () => onMethodChanged(id),
        borderRadius: AppRadii.inputRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.inputRadius,
            border: Border.all(color: border, width: 0.8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: iconColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
