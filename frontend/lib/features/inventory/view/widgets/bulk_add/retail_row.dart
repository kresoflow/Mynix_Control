import 'package:flutter/material.dart';

class RetailRowData {
  final TextEditingController nameController;
  final TextEditingController typeController;
  final TextEditingController flavorController;
  final TextEditingController volumeController;
  final TextEditingController purchaseController;
  final TextEditingController sellController;
  final TextEditingController stockController;
  final FocusNode firstFocusNode = FocusNode();
  String selectedUnit;

  RetailRowData({
    String name = '',
    String type = '',
    String flavor = '',
    String volume = '',
    String purchase = '0',
    String sell = '0',
    String stock = '0',
    this.selectedUnit = 'pcs',
  }) : nameController = TextEditingController(text: name),
       typeController = TextEditingController(text: type),
       flavorController = TextEditingController(text: flavor),
       volumeController = TextEditingController(text: volume),
       purchaseController = TextEditingController(text: purchase),
       sellController = TextEditingController(text: sell),
       stockController = TextEditingController(text: stock);

  RetailRowData clone() {
    return RetailRowData(
      name: nameController.text,
      type: typeController.text,
      flavor: flavorController.text,
      volume: volumeController.text,
      purchase: purchaseController.text,
      sell: sellController.text,
      stock: stockController.text,
      selectedUnit: selectedUnit,
    );
  }
}

class RetailRowWidget extends StatefulWidget {
  final RetailRowData row;
  final VoidCallback onAddRow;

  const RetailRowWidget({super.key, required this.row, required this.onAddRow});

  @override
  State<RetailRowWidget> createState() => _RetailRowWidgetState();
}

class _RetailRowWidgetState extends State<RetailRowWidget> {
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
            decoration: const InputDecoration(labelText: 'Название'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: widget.row.selectedUnit,
            decoration: const InputDecoration(labelText: 'Ед. изм.'),
            items: const [
              DropdownMenuItem(value: 'pcs', child: Text('шт')),
              DropdownMenuItem(value: 'l', child: Text('л')),
              DropdownMenuItem(value: 'ml', child: Text('мл')),
              DropdownMenuItem(value: 'kg', child: Text('кг')),
              DropdownMenuItem(value: 'g', child: Text('г')),
            ],
            onChanged: (val) => setState(() => widget.row.selectedUnit = val!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.typeController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Тип'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.flavorController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Вкус (через ,)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.volumeController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Объем (через ,)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.purchaseController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Закупка (с)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.sellController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Продажа (с)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.stockController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => widget.onAddRow(),
            decoration: const InputDecoration(labelText: 'Приход (шт)'),
          ),
        ),
      ],
    );
  }
}
