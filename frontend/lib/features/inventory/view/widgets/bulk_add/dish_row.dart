import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bulk_input_decoration.dart';

class DishRowData {
  final String id;
  final TextEditingController nameController;
  final TextEditingController optionsController;
  final TextEditingController priceController;
  final FocusNode firstFocusNode = FocusNode();
  int? categoryId;
  String? categoryName;

  DishRowData({
    String? id,
    String name = '',
    String options = '',
    String price = '0',
    this.categoryId,
    this.categoryName,
  }) : id = id ?? UniqueKey().toString(),
       nameController = TextEditingController(text: name),
       optionsController = TextEditingController(text: options),
       priceController = TextEditingController(text: price);

  DishRowData clone() {
    return DishRowData(
      name: nameController.text,
      options: optionsController.text,
      price: priceController.text,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}

class DishRowWidget extends StatelessWidget {
  final DishRowData row;
  final VoidCallback onAddRow;
  final VoidCallback? onFocusPrevRow;
  final VoidCallback? onFocusNextRow;

  const DishRowWidget({
    super.key,
    required this.row,
    required this.onAddRow,
    this.onFocusPrevRow,
    this.onFocusNextRow,
  });

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (onFocusNextRow != null) {
          onFocusNextRow!();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (onFocusPrevRow != null) {
          onFocusPrevRow!();
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
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.nameController,
              focusNode: row.firstFocusNode,
              textInputAction: TextInputAction.next,
              decoration: buildBulkInputDecoration(context, 'Название блюда'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.optionsController,
              textInputAction: TextInputAction.next,
              decoration: buildBulkInputDecoration(context, 'Опции (оставьте пустым, если нет)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.priceController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAddRow(),
              decoration: buildBulkInputDecoration(context, 'Цена (через запятую)'),
            ),
          ),
        ],
      ),
    );
  }
}
