import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RetailSingleProductForm extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;
  final TextEditingController initialStockController;
  final TextEditingController purchasePriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController barcodeController;
  final Map<String, String> units;

  const RetailSingleProductForm({
    super.key,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.initialStockController,
    required this.purchasePriceController,
    required this.sellingPriceController,
    required this.barcodeController,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Ед. изм.',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedUnit,
                items: units.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onUnitChanged(val);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: initialStockController,
                decoration: const InputDecoration(
                  labelText: 'Нач. остаток',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: purchasePriceController,
                decoration: const InputDecoration(
                  labelText: 'Цена закупки',
                  border: OutlineInputBorder(),
                  prefixText: 'TJS ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: sellingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Цена продажи (розница)',
                  border: OutlineInputBorder(),
                  prefixText: 'TJS ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: barcodeController,
          decoration: InputDecoration(
            labelText: 'Штрихкод',
            hintText: 'Отсканируйте или введите вручную',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
          ),
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }
}
