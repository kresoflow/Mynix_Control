import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
void showAddIngredientDialog(BuildContext context, {Ingredient? itemToEdit, int? initialCategoryId}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.name ?? '');
  final costController = TextEditingController(text: isEditing ? itemToEdit.costPerUnit.toInt().toString() : '0');
  final alertController = TextEditingController(text: isEditing ? itemToEdit.minStockAlert.toInt().toString() : '0');
  final initialStockController = TextEditingController(text: '0');
  String selectedUnit = itemToEdit?.unit ?? 'g';
  int? selectedCategoryId = itemToEdit?.categoryId ?? initialCategoryId;
  final currency = context.read<SettingsBloc>().state.currency;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return MynixDialog(
            title: isEditing ? 'Редактировать сырье' : 'Новый ингредиент',
            icon: PhosphorIconsRegular.leaf,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название сырья',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Единица измерения',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                  const SizedBox(height: 16),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      if (state is CategoryLoaded) {
                        final ingredientCategories = state.categories.where((c) => c.categoryType == 'ingredient').toList();
                        if (ingredientCategories.isNotEmpty) {
                          return DropdownButtonFormField<int>(
                            initialValue: selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Категория',
                              filled: true,
                              fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                              border: OutlineInputBorder(
                                borderRadius: AppRadii.inputRadius,
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Без категории'),
                              ),
                              ...ingredientCategories.map((cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedCategoryId = val;
                              });
                            },
                          );
                        }
                      }
                      return const SizedBox();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Себестоимость за ед. ($currency)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: alertController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Минимальный остаток (алерт)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: AppRadii.inputRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: initialStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Начальный остаток',
                        filled: true,
                        fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.inputRadius,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              AppGhostButton(
                label: 'Отмена',
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 12),
              AppPrimaryButton(
                label: isEditing ? 'Сохранить' : 'Создать',
                icon: PhosphorIconsRegular.floppyDisk,
                width: 140,
                onPressed: () {
                  final cost = double.tryParse(costController.text) ?? 0.0;
                  final alert = double.tryParse(alertController.text) ?? 0.0;
                  final stock = double.tryParse(initialStockController.text) ?? 0.0;
                  if (nameController.text.isNotEmpty) {
                    if (isEditing) {
                      context.read<IngredientBloc>().add(
                            UpdateIngredient(
                              itemToEdit.id,
                              {
                                'name': nameController.text,
                                'unit': selectedUnit,
                                'cost_per_unit': cost,
                                'min_stock_alert': alert,
                                'category_id': selectedCategoryId,
                              },
                            ),
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
                            ),
                          );
                    }
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
