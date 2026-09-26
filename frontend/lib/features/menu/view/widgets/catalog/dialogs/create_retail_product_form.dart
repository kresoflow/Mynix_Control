// ==============================================================================
// МОДУЛЬ: Меню и Каталог / Поля формы ритейл-товара
// ДОМЕН: lib/features/menu/view/widgets/catalog/dialogs/create_retail_product_form.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/widgets/icon_picker_field.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/duplicate_warning_chip.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'create_retail_product_dialog.dart';

// ─── 1. Виджет полей формы ритейл-товара ──────────────────────────────────────

class CreateRetailProductForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController flavorController;
  final TextEditingController volumeController;
  final TextEditingController sortOrderController;
  final TextEditingController sellingPriceController;
  final TextEditingController barcodeController;
  final int? selectedCategoryId;
  final String selectedUnit;
  final String? selectedIcon;
  final DuplicateMatch<MenuItem>? duplicateMatch;
  final List<Map<String, dynamic>> variations;
  final VoidCallback onAddVariation;
  final void Function(int) onRemoveVariation;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<String?> onIconChanged;
  final VoidCallback onFieldsChanged;

  const CreateRetailProductForm({
    super.key,
    required this.nameController,
    required this.flavorController,
    required this.volumeController,
    required this.sortOrderController,
    required this.sellingPriceController,
    required this.barcodeController,
    required this.selectedCategoryId,
    required this.selectedUnit,
    required this.selectedIcon,
    required this.duplicateMatch,
    required this.variations,
    required this.onAddVariation,
    required this.onRemoveVariation,
    required this.onCategoryChanged,
    required this.onUnitChanged,
    required this.onIconChanged,
    required this.onFieldsChanged,
  });

  InputDecoration _deco(String label, bool isDark, {Widget? prefix, String? suffix, String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    suffixText: suffix,
    suffixStyle: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
    filled: true,
    fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
    border: OutlineInputBorder(borderRadius: AppRadii.inputRadius, borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = context.watch<SettingsBloc>().state.currency;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, catState) {
            final cats = catState is CategoryLoaded ? catState.categories.where((c) => c.categoryType == 'retail' && !c.isArchived).toList() : [];
            final hasCat = selectedCategoryId != null && selectedCategoryId != 0 && cats.any((c) => c.id == selectedCategoryId);
            return DropdownButtonFormField<int?>(
              initialValue: hasCat ? selectedCategoryId : null,
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              decoration: _deco('Категория витрины', isDark, prefix: Icon(PhosphorIconsRegular.folderPlus, color: AppColors.brandPrimary)),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Без категории (в корень каталога)')),
                ...cats.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: onCategoryChanged,
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: nameController,
                onChanged: (_) => onFieldsChanged(),
                decoration: _deco('Название товара (Мясо, Вода, Сникерс)', isDark, prefix: Icon(PhosphorIconsRegular.storefront, color: AppColors.brandPrimary)),
                autofocus: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: flavorController,
                onChanged: (_) => onFieldsChanged(),
                decoration: _deco('Вкус (апельсин, кола...)', isDark, prefix: Icon(PhosphorIconsRegular.drop, color: AppColors.brandPrimary)),
              ),
            ),
          ],
        ),
        if (duplicateMatch != null)
          DuplicateWarningChip(
            message: duplicateMatch!.matchReason,
            onOpenExisting: () {
              Navigator.pop(context);
              showAddRetailProductDialog(context, currentCategoryId: selectedCategoryId, itemToEdit: duplicateMatch!.item);
            },
          ),
        if (variations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Фасовки и объемы (Серия)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              TextButton.icon(
                onPressed: onAddVariation,
                icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                label: const Text('Добавить объем'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...variations.asMap().entries.map((entry) {
            final idx = entry.key;
            final v = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: v['name']?.toString() ?? '',
                      decoration: _deco('Объем (0.5 л, 100г)', isDark, prefix: Icon(PhosphorIconsRegular.package, size: 16, color: AppColors.brandPrimary)),
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
                      initialValue: v['price'] != null ? (v['price'] % 1 == 0 ? v['price'].toInt().toString() : v['price'].toString()) : '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _deco('Цена', isDark, suffix: currency),
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
                      decoration: _deco('Штрихкод', isDark, prefix: Icon(PhosphorIconsRegular.barcode, size: 16, color: AppColors.brandPrimary)),
                      onChanged: (val) {
                        v['barcode'] = val.trim().isEmpty ? null : val.trim();
                        onFieldsChanged();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger, size: 18),
                    tooltip: 'Удалить',
                    onPressed: () => onRemoveVariation(idx),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: sellingPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _deco('Цена продажи на кассе', isDark, suffix: currency, prefix: Icon(PhosphorIconsRegular.tag, color: AppColors.brandPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  decoration: _deco('Ед. изм.', isDark, prefix: Icon(PhosphorIconsRegular.scales, color: AppColors.brandPrimary)),
                  items: const [
                    DropdownMenuItem(value: 'pcs', child: Text('Шт (шт)')),
                    DropdownMenuItem(value: 'kg', child: Text('Кг (кг)')),
                    DropdownMenuItem(value: 'g', child: Text('Гр (г)')),
                    DropdownMenuItem(value: 'l', child: Text('Литр (л)')),
                    DropdownMenuItem(value: 'ml', child: Text('Мл (мл)')),
                  ],
                  onChanged: (val) => val != null ? onUnitChanged(val) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: volumeController,
                  onChanged: (_) => onFieldsChanged(),
                  decoration: _deco('Объем / фасовка (0.5л, 100г)', isDark, prefix: Icon(PhosphorIconsRegular.package, color: AppColors.brandPrimary)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onAddVariation,
                icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                label: const Text('Серия объемов'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: barcodeController,
            onChanged: (_) => onFieldsChanged(),
            decoration: _deco('Штрихкод (опционально)', isDark, prefix: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: sortOrderController,
                keyboardType: TextInputType.number,
                decoration: _deco('Порядок в меню', isDark, hint: '1, 2, 3... (пусто = авто)', prefix: Icon(PhosphorIconsRegular.sortAscending, color: AppColors.brandPrimary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        IconPickerField(
          selectedIcon: selectedIcon,
          onIconSelected: onIconChanged,
        ),
      ],
    );
  }
}

