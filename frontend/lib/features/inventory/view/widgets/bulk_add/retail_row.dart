import 'package:flutter/material.dart';
import 'bulk_input_decoration.dart';

class RetailRowData {
  final TextEditingController nameController;
  final TextEditingController flavorController;
  final TextEditingController volumeController;
  final TextEditingController purchaseController;
  final TextEditingController sellController;
  final TextEditingController stockController;
  final TextEditingController alertController;
  final TextEditingController barcodeController;
  final FocusNode firstFocusNode = FocusNode();
  String selectedUnit;
  int? categoryId;
  String? categoryName;

  RetailRowData({
    String name = '',
    String flavor = '',
    String volume = '',
    String purchase = '0',
    String sell = '0',
    String stock = '0',
    String alert = '0',
    String barcode = '',
    this.selectedUnit = 'pcs',
    this.categoryId,
    this.categoryName,
  }) : nameController = TextEditingController(text: name),
       flavorController = TextEditingController(text: flavor),
       volumeController = TextEditingController(text: volume),
       purchaseController = TextEditingController(text: purchase),
       sellController = TextEditingController(text: sell),
       stockController = TextEditingController(text: stock),
       alertController = TextEditingController(text: alert),
       barcodeController = TextEditingController(text: barcode);

  RetailRowData clone() {
    return RetailRowData(
      name: nameController.text,
      flavor: flavorController.text,
      volume: volumeController.text,
      purchase: purchaseController.text,
      sell: sellController.text,
      stock: stockController.text,
      alert: alertController.text,
      barcode: barcodeController.text,
      selectedUnit: selectedUnit,
      categoryId: categoryId,
      categoryName: categoryName,
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
        // 1. Название
        Expanded(
          flex: 3,
          child: TextField(
            controller: widget.row.nameController,
            focusNode: widget.row.firstFocusNode,
            textInputAction: TextInputAction.next,
            decoration: buildBulkInputDecoration(context, 'Название'),
          ),
        ),
        const SizedBox(width: 8),
        
        // 2. Вкус
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.flavorController,
            textInputAction: TextInputAction.next,
            decoration: buildBulkInputDecoration(context, 'Вкус (или пусто)'),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Объем
        Expanded(
          flex: 1,
          child: TextField(
            controller: widget.row.volumeController,
            textInputAction: TextInputAction.next,
            decoration: buildBulkInputDecoration(context, 'Объем (или пусто)'),
          ),
        ),
        const SizedBox(width: 8),

        // 4. Ед. изм.
        SizedBox(
          width: 85,
          child: DropdownButtonFormField<String>(
            initialValue: widget.row.selectedUnit,
            decoration: buildBulkInputDecoration(context, 'Ед. изм.'),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            padding: EdgeInsets.zero,
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

        // 4.5 Barcode
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.row.barcodeController,
            textInputAction: TextInputAction.next,
            decoration: buildBulkInputDecoration(context, 'Штрихкоды (через ,)'),
          ),
        ),
        const SizedBox(width: 8),

        // 5. Количество / Нач. остаток
        Expanded(
          flex: 1,
          child: TextField(
            controller: widget.row.stockController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            decoration: buildBulkInputDecoration(context, 'Остаток (через ,)'),
          ),
        ),
        const SizedBox(width: 8),

        // 6. Алерт
        Expanded(
          flex: 1,
          child: TextField(
            controller: widget.row.alertController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            decoration: buildBulkInputDecoration(context, 'Алерт (через ,)'),
          ),
        ),
        const SizedBox(width: 8),

        // 7. Закупка
        Expanded(
          flex: 1,
          child: TextField(
            controller: widget.row.purchaseController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            decoration: buildBulkInputDecoration(context, 'Закупка (через ,)'),
          ),
        ),
        const SizedBox(width: 8),

        // 8. Продажа
        Expanded(
          flex: 1,
          child: TextField(
            controller: widget.row.sellController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text,
            onSubmitted: (_) => widget.onAddRow(),
            decoration: buildBulkInputDecoration(context, 'Продажа (через ,)'),
          ),
        ),
      ],
    );
  }
}
