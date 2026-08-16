import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/inventory/models/supplier.dart';

class ReceiveDocumentSupplierSelect extends StatelessWidget {
  final List<Supplier> suppliers;
  final int? selectedSupplierId;
  final ValueChanged<int?> onSupplierChanged;
  final VoidCallback onAddSupplier;
  final bool isDark;

  const ReceiveDocumentSupplierSelect({
    super.key,
    required this.suppliers,
    required this.selectedSupplierId,
    required this.onSupplierChanged,
    required this.onAddSupplier,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: DropdownButtonFormField<int?>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Поставщик (необязательно)',
                labelStyle: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                filled: true,
                fillColor: bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                prefixIcon: const Icon(PhosphorIconsRegular.buildings, size: 18),
              ),
              initialValue: selectedSupplierId,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Без поставщика'),
                ),
                ...suppliers.map((s) {
                  return DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  );
                }),
              ],
              onChanged: onSupplierChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Добавить поставщика',
          child: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(PhosphorIconsRegular.plus, size: 18),
              color: AppColors.brandPrimary,
              onPressed: onAddSupplier,
            ),
          ),
        ),
      ],
    );
  }
}
