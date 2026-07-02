import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class RetailCategoryDropdown extends StatelessWidget {
  final int? selectedCategoryId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onCreateCategory;

  const RetailCategoryDropdown({
    super.key,
    required this.selectedCategoryId,
    required this.onChanged,
    required this.onCreateCategory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedCategoryId,
                  items: state.categories.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  validator: (v) => v == null ? 'Выберите категорию' : null,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.plusSquare,
                    size: 40,
                    color: AppColors.brandPrimary,
                  ),
                  onPressed: onCreateCategory,
                  tooltip: 'Новая категория',
                ),
              ),
            ],
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

class RetailUnitAndStockRow extends StatelessWidget {
  final String selectedUnit;
  final Map<String, String> units;
  final ValueChanged<String?> onUnitChanged;
  final TextEditingController stockController;

  const RetailUnitAndStockRow({
    super.key,
    required this.selectedUnit,
    required this.units,
    required this.onUnitChanged,
    required this.stockController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
            onChanged: onUnitChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: stockController,
            decoration: const InputDecoration(
              labelText: 'Нач. остаток',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
          ),
        ),
      ],
    );
  }
}

class RetailPriceRow extends StatelessWidget {
  final TextEditingController purchasePriceController;
  final TextEditingController sellingPriceController;
  final String currency;

  const RetailPriceRow({
    super.key,
    required this.purchasePriceController,
    required this.sellingPriceController,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: purchasePriceController,
            decoration: InputDecoration(
              labelText: 'Цена закупки',
              border: const OutlineInputBorder(),
              prefixText: '$currency ',
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: sellingPriceController,
            decoration: InputDecoration(
              labelText: 'Цена продажи (розница)',
              border: const OutlineInputBorder(),
              prefixText: '$currency ',
            ),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Заполните' : null,
          ),
        ),
      ],
    );
  }
}
