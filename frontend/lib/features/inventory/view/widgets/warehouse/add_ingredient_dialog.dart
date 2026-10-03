import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:kreso_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';

class AddIngredientDialog extends StatefulWidget {
  const AddIngredientDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddIngredientDialog());
  }

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final nameController = TextEditingController();
  final costController = TextEditingController(text: '0');
  final alertController = TextEditingController(text: '0');
  String selectedUnit = 'g';

  @override
  void dispose() {
    nameController.dispose();
    costController.dispose();
    alertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый ингредиент / сырье'),
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
              initialValue: selectedUnit,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Единица измерения'),
              items: UnitFormatter.dropdownItems,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Себестоимость за ед. (с)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alertController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Минимальный остаток (алерт)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final cost = double.tryParse(costController.text) ?? 0.0;
            final alert = double.tryParse(alertController.text) ?? 0.0;
            if (nameController.text.isNotEmpty) {
              context.read<IngredientBloc>().add(
                CreateIngredient(
                  name: nameController.text,
                  unit: selectedUnit,
                  costPerUnit: cost,
                  minStockAlert: alert,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
