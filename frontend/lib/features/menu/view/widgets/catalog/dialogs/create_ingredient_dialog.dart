// ==============================================================================
// Title: CreateIngredientDialog
// Path: frontend/lib/features/menu/view/widgets/catalog/dialogs/create_ingredient_dialog.dart
// Description: Диалог создания и редактирования сырья со встроенной защитой от дублей.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/features/menu/services/duplicate_detector.dart';
import 'package:kreso_frontend/features/menu/view/widgets/catalog/dialogs/create_ingredient_form_fields.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';

// [UI-KIT] Показ модального окна добавления/редактирования сырья
void showAddIngredientDialog(BuildContext context, {Ingredient? itemToEdit, int? initialCategoryId}) {
  final isEditing = itemToEdit != null;
  final initialName = itemToEdit?.name ?? '';
  final initialSort = (itemToEdit != null && itemToEdit.sortOrder > 0) ? itemToEdit.sortOrder.toString() : '';
  final initialCost = isEditing ? itemToEdit.costPerUnit.toInt().toString() : '0';
  final initialAlert = isEditing ? itemToEdit.minStockAlert.toInt().toString() : '0';
  final initialBarcode = isEditing ? itemToEdit.barcode ?? '' : '';
  final initialUnit = UnitFormatter.toDbKey(itemToEdit?.unit, 'g');
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

          void onSubmit() {
            final cost = double.tryParse(costController.text) ?? 0.0;
            final alert = double.tryParse(alertController.text) ?? 0.0;
            final stock = double.tryParse(initialStockController.text) ?? 0.0;
            final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
            if (nameController.text.isEmpty) return;

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
                child: CreateIngredientFormFields(
                  nameController: nameController,
                  sortOrderController: sortOrderController,
                  costController: costController,
                  alertController: alertController,
                  initialStockController: initialStockController,
                  barcodeController: barcodeController,
                  selectedUnit: selectedUnit,
                  selectedCategoryId: selectedCategoryId,
                  isEditing: isEditing,
                  currency: currency,
                  duplicateMatch: duplicateMatch,
                  onCategoryChanged: (val) {
                    setState(() {
                      selectedCategoryId = val;
                      if (!isEditing || barcodeController.text.isEmpty || barcodeController.text.contains('-')) {
                        barcodeController.text = generateNextSku(val);
                      }
                    });
                  },
                  onUnitChanged: (val) => setState(() => selectedUnit = val),
                  onGenerateSku: () => setState(() => barcodeController.text = generateNextSku(selectedCategoryId)),
                  onOpenExistingDuplicate: () {
                    Navigator.pop(ctx);
                    showAddIngredientDialog(
                      context,
                      itemToEdit: duplicateMatch!.item,
                      initialCategoryId: selectedCategoryId,
                    );
                  },
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
                  onPressed: onSubmit,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
