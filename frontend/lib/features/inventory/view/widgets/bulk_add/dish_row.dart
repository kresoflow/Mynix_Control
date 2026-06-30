import 'package:flutter/material.dart';
import 'bulk_input_decoration.dart';

class DishRowData {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final FocusNode firstFocusNode = FocusNode();

  DishRowData({String name = '', String price = '0'})
    : nameController = TextEditingController(text: name),
      priceController = TextEditingController(text: price);

  DishRowData clone() {
    return DishRowData(name: nameController.text, price: priceController.text);
  }
}

class DishRowWidget extends StatelessWidget {
  final DishRowData row;
  final VoidCallback onAddRow;

  const DishRowWidget({super.key, required this.row, required this.onAddRow});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          flex: 2,
          child: TextField(
            controller: row.priceController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAddRow(),
            decoration: buildBulkInputDecoration(context, 'Цена продажи (с)'),
          ),
        ),
      ],
    );
  }
}

