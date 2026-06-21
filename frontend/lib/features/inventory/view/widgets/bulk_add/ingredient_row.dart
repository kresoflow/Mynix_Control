import 'package:flutter/material.dart';

class IngredientRowData {
  final TextEditingController nameController;
  final TextEditingController costController;
  final TextEditingController alertController;
  final TextEditingController stockController;
  final FocusNode firstFocusNode = FocusNode();
  String selectedUnit;

  IngredientRowData({
    String name = '',
    String cost = '0',
    String alert = '0',
    String stock = '0',
    this.selectedUnit = 'g',
  }) : nameController = TextEditingController(text: name),
       costController = TextEditingController(text: cost),
       alertController = TextEditingController(text: alert),
       stockController = TextEditingController(text: stock);

  IngredientRowData clone() {
    return IngredientRowData(
      name: nameController.text,
      cost: costController.text,
      alert: alertController.text,
      stock: stockController.text,
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
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: widget.row.selectedUnit,
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
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.costController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Себест. (с)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.stockController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Кол-во (Приход)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.alertController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => widget.onAddRow(),
            decoration: const InputDecoration(labelText: 'Мин. остаток'),
          ),
        ),
      ],
    );
  }
}
