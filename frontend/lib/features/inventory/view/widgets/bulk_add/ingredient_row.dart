import 'package:flutter/material.dart';
import 'bulk_input_decoration.dart';

class IngredientRowData {
  final TextEditingController nameController;
  final TextEditingController stockController;
  final TextEditingController alertController;
  final TextEditingController costController;
  final FocusNode firstFocusNode = FocusNode();
  String selectedUnit;

  IngredientRowData({
    String name = '',
    String stock = '0',
    String alert = '0',
    String cost = '0',
    this.selectedUnit = 'g',
  }) : nameController = TextEditingController(text: name),
       stockController = TextEditingController(text: stock),
       alertController = TextEditingController(text: alert),
       costController = TextEditingController(text: cost);

  IngredientRowData clone() {
    return IngredientRowData(
      name: nameController.text,
      stock: stockController.text,
      alert: alertController.text,
      cost: costController.text,
      selectedUnit: selectedUnit,
    );
  }
}

class IngredientRowWidget extends StatefulWidget {
  final IngredientRowData row;
  final VoidCallback onAddRow;

  const IngredientRowWidget({
    super.key,
    required this.row,
    required this.onAddRow,
  });

  @override
  State<IngredientRowWidget> createState() => _IngredientRowWidgetState();
}

class _IngredientRowWidgetState extends State<IngredientRowWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Название
        Expanded(
          flex: 3,
          child: TextField(
            controller: widget.row.nameController,
            focusNode: widget.row.firstFocusNode,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Название сырья'),
          ),
        ),
        const SizedBox(width: 8),

        // 4. Ед. изм. (skip flavor/volume for ingredients, so it matches position)
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: widget.row.selectedUnit,
            decoration: const InputDecoration(labelText: 'Ед. изм.'),
            items: const [
              DropdownMenuItem(value: 'pcs', child: Text('Штуки')),
              DropdownMenuItem(value: 'g', child: Text('Граммы')),
              DropdownMenuItem(value: 'kg', child: Text('Килограммы')),
              DropdownMenuItem(value: 'ml', child: Text('Миллилитры')),
              DropdownMenuItem(value: 'l', child: Text('Литры')),
            ],
            onChanged: (val) => setState(() => widget.row.selectedUnit = val!),
          ),
        ),
        const SizedBox(width: 8),

        // 5. Начальный остаток
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.stockController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            decoration: buildBulkInputDecoration(context, 'Остаток'),
          ),
        ),
        const SizedBox(width: 8),

        // 6. Алерт
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.alertController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            decoration: buildBulkInputDecoration(context, 'Алерт'),
          ),
        ),
        const SizedBox(width: 8),

        // 7. Закупка (Себестоимость)
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.costController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => widget.onAddRow(),
            decoration: buildBulkInputDecoration(context, 'Закупка'),
          ),
        ),
      ],
    );
  }
}
