// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Строка вариации серии ритейл-товара
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/retail_variation_row.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';

// ─── 1. Виджет строки фасовки/объема серии ────────────────────────────────────

/// Строка ввода объема, цены и штрихкода для серийного товара витрины.
class RetailVariationRow extends StatelessWidget {
  final Map<String, dynamic> variation;
  final String currency;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onFieldsChanged;
  final VoidCallback? onExtract;

  const RetailVariationRow({
    super.key,
    required this.variation,
    required this.currency,
    required this.isDark,
    required this.onRemove,
    required this.onFieldsChanged,
    this.onExtract,
  });

  InputDecoration _inputDeco(String label, {Widget? prefix, String? suffix}) => InputDecoration(
    labelText: label,
    prefixIcon: prefix,
    suffixText: suffix,
    suffixStyle: TextStyle(
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    ),
    filled: true,
    fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: const OutlineInputBorder(borderRadius: AppRadii.inputRadius, borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    final v = variation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: v['name']?.toString() ?? '',
              decoration: _inputDeco(
                'Объем (напр. 0.5, 1)',
                prefix: Icon(PhosphorIconsRegular.package, size: 16, color: AppColors.brandPrimary),
              ),
              onChanged: (val) {
                v['name'] = val;
                onFieldsChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: v['price'] != null
                  ? (v['price'] % 1 == 0 ? v['price'].toInt().toString() : v['price'].toString())
                  : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco('Цена', suffix: currency),
              onChanged: (val) {
                v['price'] = double.tryParse(val) ?? 0.0;
                onFieldsChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: v['barcode']?.toString() ?? '',
              decoration: _inputDeco(
                'Штрихкод',
                prefix: Icon(PhosphorIconsRegular.barcode, size: 16, color: AppColors.brandPrimary),
              ),
              onChanged: (val) {
                v['barcode'] = val.trim().isEmpty ? null : val.trim();
                onFieldsChanged();
              },
            ),
          ),
          if (onExtract != null)
            IconButton(
              icon: Icon(
                PhosphorIconsRegular.arrowSquareOut,
                size: 18,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              tooltip: 'Отсоединить в отдельный товар',
              onPressed: onExtract,
            ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x, size: 18, color: AppColors.danger),
            tooltip: 'Удалить вариант',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
