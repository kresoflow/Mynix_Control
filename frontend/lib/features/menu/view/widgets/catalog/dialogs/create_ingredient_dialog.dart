import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';

void showAddIngredientDialog(BuildContext context, {Ingredient? itemToEdit}) {
  final isEditing = itemToEdit != null;
  final nameController = TextEditingController(text: itemToEdit?.name ?? '');
  final costController = TextEditingController(text: isEditing ? itemToEdit.costPerUnit.toInt().toString() : '0');
  final alertController = TextEditingController(text: isEditing ? itemToEdit.minStockAlert.toInt().toString() : '0');
  String selectedUnit = itemToEdit?.unit ?? 'g';

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
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Себестоимость за ед. (₽)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: alertController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Минимальный остаток (алерт)'),
                  ),
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
