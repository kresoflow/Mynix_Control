import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/duplicate_warning_chip.dart';

void showAddIngredientDialog(BuildContext context, {Ingredient? itemToEdit, int? initialCategoryId}) {
  final isEditing = itemToEdit != null;
  final initialName = itemToEdit?.name ?? '';
  final initialSort = (itemToEdit != null && itemToEdit.sortOrder > 0) ? itemToEdit.sortOrder.toString() : '';
  final initialCost = isEditing ? itemToEdit.costPerUnit.toInt().toString() : '0';
  final initialAlert = isEditing ? itemToEdit.minStockAlert.toInt().toString() : '0';
  final initialBarcode = isEditing ? itemToEdit.barcode ?? '' : '';
  final initialUnit = itemToEdit?.unit ?? 'g';
  final initialCat = (itemToEdit?.categoryId == 0) ? null : (itemToEdit?.categoryId ?? initialCategoryId);

  final nameController = TextEditingController(text: initialName);
  final sortOrderController = TextEditingController(text: initialSort);
  final costController = TextEditingController(text: initialCost);
  final alertController = TextEditingController(text: initialAlert);
  final initialStockController = TextEditingController(text: '0');
  final barcodeController = TextEditingController(text: initialBarcode);
  String selectedUnit = initialUnit;
  int? selectedCategoryId = initialCat;
  final currency = context.read<SettingsBloc>().state.currency;

  String generateNextSku(int? catId) {
    if (catId == null) return '';
    final catState = context.read<CategoryBloc>().state;
    final ingState = context.read<IngredientBloc>().state;
    if (catState is! CategoryLoaded || ingState is! IngredientLoaded) return '';

    final ingredientCategories = catState.categories.where((c) => c.categoryType == 'ingredient').toList();
    final catIndex = ingredientCategories.indexWhere((c) => c.id == catId);
    final prefix = catIndex >= 0 ? (catIndex + 1) * 10 : 10;

    final itemsInCat = ingState.ingredients.where((i) => i.categoryId == catId && (itemToEdit == null || i.id != itemToEdit.id)).length;
    final seq = (itemsInCat + 1).toString().padLeft(2, '0');
    return '$prefix-$seq';
  }

  if (!isEditing && barcodeController.text.isEmpty && selectedCategoryId != null) {
    barcodeController.text = generateNextSku(selectedCategoryId);
  }

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          nameController.addListener(() {
            if (ctx.mounted) setState(() {});
          });
          barcodeController.addListener(() {
            if (ctx.mounted) setState(() {});
          });

          final isDark = Theme.of(context).brightness == Brightness.dark;

          final ingState = context.watch<IngredientBloc>().state;
          DuplicateMatch? duplicateMatch;
          if (ingState is IngredientLoaded) {
            duplicateMatch = DuplicateDetector.findIngredientDuplicate(
              ingredients: ingState.ingredients,
              queryName: nameController.text,
              queryBarcode: barcodeController.text,
              currentCategoryId: selectedCategoryId,
              excludeIngredientId: itemToEdit?.id,
            );
          }

          bool isDirty() {
            if (nameController.text.trim() != initialName.trim()) return true;
            if (selectedUnit != initialUnit) return true;
            if (costController.text.trim() != initialCost.trim()) return true;
            if (alertController.text.trim() != initialAlert.trim()) return true;
            if (!isEditing && initialStockController.text.trim() != '0' && initialStockController.text.trim().isNotEmpty) return true;
            if (barcodeController.text.trim() != initialBarcode.trim() && barcodeController.text.trim().isNotEmpty) return true;
            if (sortOrderController.text.trim() != initialSort.trim()) return true;
            if (selectedCategoryId != initialCat) return true;
            return false;
          }

          InputDecoration inputDeco(String label, {Widget? prefixIcon, Widget? suffixIcon, String? hintText}) {
            return InputDecoration(
              labelText: label,
              hintText: hintText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              border: OutlineInputBorder(
                borderRadius: AppRadii.inputRadius,
                borderSide: BorderSide.none,
              ),
            );
          }

          void showDuplicateBlockedDialog(BuildContext dialogCtx, Ingredient existingItem) {
            showDialog(
              context: dialogCtx,
              builder: (alertCtx) => AppDialog(
                title: 'Сырье уже существует',
                icon: PhosphorIconsRegular.warningCircle,
                width: 440,
                content: Text(
                  'На складе уже есть активное сырье «${existingItem.name}».\n\nОткрыть существующую карточку для редактирования?',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                actions: [
                  AppGhostButton(
                    label: 'Отмена',
                    onPressed: () => Navigator.pop(alertCtx),
                  ),
                  const SizedBox(width: 8),
                  AppPrimaryButton(
                    label: 'Открыть карточку',
                    icon: PhosphorIconsRegular.arrowSquareOut,
                    onPressed: () {
                      Navigator.pop(alertCtx);
                      Navigator.pop(dialogCtx);
                      showAddIngredientDialog(
                        context,
                        itemToEdit: existingItem,
                        initialCategoryId: selectedCategoryId,
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return DirtyPopScope(
            isDirty: isDirty(),
            title: isEditing ? 'Отменить изменения?' : 'Отменить создание?',
            message: isEditing
                ? 'Несохраненные изменения карточки сырья будут потеряны. Выйти?'
                : 'Введенные данные будут потеряны. Выйти?',
            confirmLabel: 'Сбросить и выйти',
            child: AppDialog(
              title: isEditing ? 'Редактировать сырье' : 'Новый ингредиент',
              icon: PhosphorIconsRegular.leaf,
              width: 500,
              content: SingleChildScrollView(
                child: Column(
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
                            decoration: inputDeco('Категория склада', prefixIcon: Icon(PhosphorIconsRegular.folderPlus, color: AppColors.brandPrimary)),
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Без категории')),
                              ...ingredientCategories.map((cat) => DropdownMenuItem<int?>(value: cat.id, child: Text(cat.name))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedCategoryId = val;
                                if (!isEditing || barcodeController.text.isEmpty || barcodeController.text.contains('-')) {
                                  barcodeController.text = generateNextSku(val);
                                }
                              });
                            },
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
                            decoration: inputDeco('Название сырья', prefixIcon: Icon(PhosphorIconsRegular.leaf, color: AppColors.brandPrimary)),
                            autofocus: !isEditing,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            decoration: inputDeco('Ед. изм.', prefixIcon: Icon(PhosphorIconsRegular.scales, color: AppColors.brandPrimary)),
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            items: const [
                              DropdownMenuItem(value: 'pcs', child: Text('Штуки (шт)')),
                              DropdownMenuItem(value: 'g', child: Text('Граммы (г)')),
                              DropdownMenuItem(value: 'kg', child: Text('Килограммы (кг)')),
                              DropdownMenuItem(value: 'ml', child: Text('Миллилитры (мл)')),
                              DropdownMenuItem(value: 'l', child: Text('Литры (л)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedUnit = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (duplicateMatch != null)
                      DuplicateWarningChip(
                        message: duplicateMatch.matchReason,
                        onOpenExisting: () {
                          Navigator.pop(ctx);
                          showAddIngredientDialog(
                            context,
                            itemToEdit: duplicateMatch!.item,
                            initialCategoryId: selectedCategoryId,
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: inputDeco('Себестоимость за ед. ($currency)', prefixIcon: Icon(PhosphorIconsRegular.tag, color: AppColors.brandPrimary)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: alertController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: inputDeco('Мин. остаток (алерт)', prefixIcon: Icon(PhosphorIconsRegular.warning, color: AppColors.brandPrimary)),
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
                            decoration: inputDeco(
                              'Артикул / SKU (или штрихкод)',
                              prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                              suffixIcon: IconButton(
                                icon: Icon(PhosphorIconsRegular.sparkle, color: AppColors.brandPrimary),
                                tooltip: 'Автогенерация серийного SKU',
                                onPressed: () {
                                  setState(() {
                                    barcodeController.text = generateNextSku(selectedCategoryId);
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: sortOrderController,
                            keyboardType: TextInputType.number,
                            decoration: inputDeco(
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
                        decoration: inputDeco('Начальный остаток на складе', prefixIcon: Icon(PhosphorIconsRegular.package, color: AppColors.brandPrimary)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                AppGhostButton(
                  label: 'Отмена',
                  onPressed: () => Navigator.maybePop(ctx),
                ),
                const SizedBox(width: 12),
                AppPrimaryButton(
                  label: isEditing ? 'Сохранить' : 'Создать',
                  icon: PhosphorIconsRegular.floppyDisk,
                  width: null,
                  onPressed: () {
                    final cost = double.tryParse(costController.text) ?? 0.0;
                    final alert = double.tryParse(alertController.text) ?? 0.0;
                    final stock = double.tryParse(initialStockController.text) ?? 0.0;
                    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
                    if (nameController.text.isNotEmpty) {
                      final barcode = barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim();
                      if (!isEditing && duplicateMatch != null && duplicateMatch.isSameCategory) {
                        showDuplicateBlockedDialog(ctx, duplicateMatch.item);
                        return;
                      }
                      if (isEditing) {
                        context.read<IngredientBloc>().add(
                          UpdateIngredient(itemToEdit.id, {
                            'name': nameController.text,
                            'unit': selectedUnit,
                            'cost_per_unit': cost,
                            'min_stock_alert': alert,
                            'category_id': selectedCategoryId,
                            'sort_order': sortOrder,
                            'barcode': barcode,
                          }),
                        );
                      } else {
                        context.read<IngredientBloc>().add(
                          CreateIngredient(
                            name: nameController.text,
                            unit: selectedUnit,
                            costPerUnit: cost,
                            minStockAlert: alert,
                            categoryId: selectedCategoryId,
                            initialStock: stock,
                            sortOrder: sortOrder,
                            barcode: barcode,
                          ),
                        );
                      }
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
