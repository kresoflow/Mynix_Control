import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bulk_input_decoration.dart';

class RetailRowData {
  final String id;
  final TextEditingController nameController;
  final TextEditingController flavorController;
  final TextEditingController volumeController;
  final TextEditingController sellController;
  final TextEditingController barcodeController;
  final FocusNode firstFocusNode = FocusNode();
  String selectedUnit;
  int? categoryId;
  String? categoryName;

  RetailRowData({
    String? id,
    String name = '',
    String flavor = '',
    String volume = '',
    String sell = '0',
    String barcode = '',
    this.selectedUnit = 'pcs',
    this.categoryId,
    this.categoryName,
  }) : id = id ?? UniqueKey().toString(),
       nameController = TextEditingController(text: name),
       flavorController = TextEditingController(text: flavor),
       volumeController = TextEditingController(text: volume),
       sellController = TextEditingController(text: sell),
       barcodeController = TextEditingController(text: barcode);

  RetailRowData clone() {
    return RetailRowData(
      name: nameController.text,
      flavor: flavorController.text,
      volume: volumeController.text,
      sell: sellController.text,
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
  final VoidCallback? onFocusPrevRow;
  final VoidCallback? onFocusNextRow;

  const RetailRowWidget({
    super.key,
    required this.row,
    required this.onAddRow,
    this.onFocusPrevRow,
    this.onFocusNextRow,
  });

  @override
  State<RetailRowWidget> createState() => _RetailRowWidgetState();
}

class _RetailRowWidgetState extends State<RetailRowWidget> {
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (widget.onFocusNextRow != null) {
          widget.onFocusNextRow!();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (widget.onFocusPrevRow != null) {
          widget.onFocusPrevRow!();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Row(
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

          // 5. Штрихкод
          Expanded(
            flex: 2,
            child: TextField(
              controller: widget.row.barcodeController,
              textInputAction: TextInputAction.next,
              decoration: buildBulkInputDecoration(context, 'Штрихкоды (через ,)'),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Цена продажи
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
      ),
    );
  }
}

