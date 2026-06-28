import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';
import 'package:retail_os_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:retail_os_frontend/features/settings/bloc/settings_bloc.dart';

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
          return AlertDialog(
            title: Text(isEditing ? 'Редактировать сырье' : 'Новый ингредиент'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название сырья'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: 'Единица измерения'),
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
                            value: selectedCategoryId,
                            decoration: const InputDecoration(labelText: 'Категория'),
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
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Себестоимость за ед. ($currency)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: alertController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Минимальный остаток (алерт)'),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: initialStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Начальный остаток'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
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
                child: Text(isEditing ? 'Сохранить' : 'Создать'),
              ),
            ],
          );
        },
      );
    },
  );
}
