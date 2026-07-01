import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class WriteOffDialog extends StatefulWidget {
  final Ingredient item;

  const WriteOffDialog({super.key, required this.item});

  static void show(BuildContext context, Ingredient item) {
    showDialog(
      context: context,
      builder: (_) => WriteOffDialog(item: item),
    );
  }

  @override
  State<WriteOffDialog> createState() => _WriteOffDialogState();
}

class _WriteOffDialogState extends State<WriteOffDialog> {
  final qtyController = TextEditingController();
  final reasonController = TextEditingController(text: 'Порча');

  @override
  void dispose() {
    qtyController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Списать: ${widget.item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Количество (${widget.item.unit})',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: 'Порча',
            decoration: const InputDecoration(labelText: 'Причина списания'),
            items: const [
              DropdownMenuItem(
                value: 'Порча',
                child: Text('Порча / Просрочка'),
              ),
              DropdownMenuItem(value: 'Брак', child: Text('Брак / Разбили')),
              DropdownMenuItem(
                value: 'Питание персонала',
                child: Text('Питание персонала'),
              ),
              DropdownMenuItem(
                value: 'Угощение гостя',
                child: Text('Угощение гостя'),
              ),
              DropdownMenuItem(value: 'Прочее', child: Text('Прочее')),
            ],
            onChanged: (val) {
              reasonController.text = val ?? '';
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final qty = double.tryParse(qtyController.text) ?? 0;
            if (qty > 0) {
              context.read<IngredientBloc>().add(
                ReceiveStock(
                  ingredientId: widget.item.id,
                  quantity: -qty, // Negative for deduction
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'Списание',
                  isRetail: widget.item.attributes?['is_retail'] == true,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Списать'),
        ),
      ],
    );
  }
}
