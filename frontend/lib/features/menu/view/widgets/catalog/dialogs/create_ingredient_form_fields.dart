// ==============================================================================
// Title: CreateIngredientFormFields
// Path: frontend/lib/features/menu/view/widgets/catalog/dialogs/create_ingredient_form_fields.dart
// Description: Поля формы создания и редактирования сырья (категория, ед. изм., себестоимость, SKU).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/duplicate_warning_chip.dart';

// [UI-KIT] Блок полей ввода диалога создания/редактирования сырья
class CreateIngredientFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController sortOrderController;
  final TextEditingController costController;
  final TextEditingController alertController;
  final TextEditingController initialStockController;
  final TextEditingController barcodeController;
  final String selectedUnit;
  final int? selectedCategoryId;
  final bool isEditing;
  final String currency;
  final DuplicateMatch? duplicateMatch;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onGenerateSku;
  final VoidCallback onOpenExistingDuplicate;

  const CreateIngredientFormFields({
    super.key,
    required this.nameController,
    required this.sortOrderController,
    required this.costController,
    required this.alertController,
    required this.initialStockController,
    required this.barcodeController,
    required this.selectedUnit,
    required this.selectedCategoryId,
    required this.isEditing,
    required this.currency,
    required this.duplicateMatch,
    required this.onCategoryChanged,
    required this.onUnitChanged,
    required this.onGenerateSku,
    required this.onOpenExistingDuplicate,
  });

  InputDecoration _inputDeco(BuildContext context, String label, {Widget? prefixIcon, Widget? suffixIcon, String? hintText, EdgeInsetsGeometry? contentPadding}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
      filled: true,
      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      border: OutlineInputBorder(
        borderRadius: AppRadii.inputRadius,
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoaded) {
              final ingredientCategories = state.categories.where((c) => c.categoryType == 'ingredient').toList();
              final bool hasMatchingCategory = selectedCategoryId != null &&
                  selectedCategoryId != 0 &&
                  ingredientCategories.any((c) => c.id == selectedCategoryId);
              final int? effectiveCategoryId = hasMatchingCategory ? selectedCategoryId : null;

              return DropdownButtonFormField<int?>(
                initialValue: effectiveCategoryId,
                decoration: _inputDeco(context, 'Категория склада', prefixIcon: Icon(PhosphorIconsRegular.folderPlus, color: AppColors.brandPrimary)),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Без категории')),
                  ...ingredientCategories.map((cat) => DropdownMenuItem<int?>(value: cat.id, child: Text(cat.name))),
                ],
                onChanged: onCategoryChanged,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: nameController,
                decoration: _inputDeco(context, 'Название сырья', prefixIcon: Icon(PhosphorIconsRegular.leaf, color: AppColors.brandPrimary)),
                autofocus: !isEditing,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: selectedUnit,
                isExpanded: true,
                decoration: _inputDeco(
                  context,
                  'Ед. изм.',
                  prefixIcon: Icon(PhosphorIconsRegular.scales, size: 18, color: AppColors.brandPrimary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                items: UnitFormatter.dropdownItems,
                onChanged: (val) {
                  if (val != null) onUnitChanged(val);
                },
              ),
            ),
          ],
        ),
        if (duplicateMatch != null)
          DuplicateWarningChip(
            message: duplicateMatch!.matchReason,
            onOpenExisting: onOpenExistingDuplicate,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeco(context, 'Себестоимость за ед. ($currency)', prefixIcon: Icon(PhosphorIconsRegular.tag, color: AppColors.brandPrimary)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: alertController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeco(context, 'Мин. остаток (алерт)', prefixIcon: Icon(PhosphorIconsRegular.warning, color: AppColors.brandPrimary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: barcodeController,
                decoration: _inputDeco(
                  context,
                  'Артикул / SKU (или штрихкод)',
                  prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                  suffixIcon: IconButton(
                    icon: Icon(PhosphorIconsRegular.sparkle, color: AppColors.brandPrimary),
                    tooltip: 'Автогенерация серийного SKU',
                    onPressed: onGenerateSku,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: sortOrderController,
                keyboardType: TextInputType.number,
                decoration: _inputDeco(
                  context,
                  'Порядок (1, 2, 3...)',
                  hintText: 'Пусто = авто',
                  prefixIcon: Icon(PhosphorIconsRegular.sortAscending, color: AppColors.brandPrimary),
                ),
              ),
            ),
          ],
        ),
        if (!isEditing) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: initialStockController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDeco(context, 'Начальный остаток на складе', prefixIcon: Icon(PhosphorIconsRegular.package, color: AppColors.brandPrimary)),
          ),
        ],
      ],
    );
  }
}
