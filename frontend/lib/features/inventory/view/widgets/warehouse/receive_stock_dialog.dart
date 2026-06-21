import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:retail_os_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:retail_os_frontend/features/inventory/models/ingredient.dart';

class ReceiveStockDialog extends StatefulWidget {
  final Ingredient item;

  const ReceiveStockDialog({super.key, required this.item});

  static void show(BuildContext context, Ingredient item) {
    showDialog(
      context: context,
      builder: (_) => ReceiveStockDialog(item: item),
    );
  }

  @override
  State<ReceiveStockDialog> createState() => _ReceiveStockDialogState();
}

class _ReceiveStockDialogState extends State<ReceiveStockDialog> {
  final qtyController = TextEditingController();
  final reasonController = TextEditingController(text: 'Поступление товара');

  @override
  void dispose() {
    qtyController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Оформить приход: ${widget.item.name}'),
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
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Причина / Комментарий',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final qty = double.tryParse(qtyController.text) ?? 0;
            if (qty > 0) {
              context.read<IngredientBloc>().add(
                ReceiveStock(
                  ingredientId: widget.item.id,
                  quantity: qty,
                  reason: reasonController.text,
                  isRetail: widget.item.attributes?['is_retail'] == true,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
