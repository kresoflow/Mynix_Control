import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bulk_input_decoration.dart';

class IngredientRowData {
  final String id;
  final TextEditingController nameController;
  final TextEditingController costController;
  final FocusNode firstFocusNode = FocusNode();
  String selectedUnit;
  int? categoryId;
  String? categoryName;
  String? sku;

  IngredientRowData({
    String? id,
    String name = '',
    String cost = '0',
    String selectedUnit = 'g',
    this.categoryId,
    this.categoryName,
    this.sku,
  }) : id = id ?? UniqueKey().toString(),
       nameController = TextEditingController(text: name),
       costController = TextEditingController(text: cost),
       selectedUnit = _normalizeUnit(selectedUnit);

  static String _normalizeUnit(String unit) {
    if (unit == 'шт' || unit == 'pcs') return 'pcs';
    if (unit == 'кг' || unit == 'kg') return 'kg';
    if (unit == 'г' || unit == 'g') return 'g';
    if (unit == 'л' || unit == 'l') return 'l';
    if (unit == 'мл' || unit == 'ml') return 'ml';
    return 'pcs';
  }

  IngredientRowData clone() {
    return IngredientRowData(
      name: nameController.text,
      cost: costController.text,
      selectedUnit: selectedUnit,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}

class IngredientRowWidget extends StatefulWidget {
  final IngredientRowData row;
  final VoidCallback onAddRow;
  final VoidCallback? onFocusPrevRow;
  final VoidCallback? onFocusNextRow;

  const IngredientRowWidget({
    super.key,
    required this.row,
    required this.onAddRow,
    this.onFocusPrevRow,
    this.onFocusNextRow,
  });

  @override
  State<IngredientRowWidget> createState() => _IngredientRowWidgetState();
}

class _IngredientRowWidgetState extends State<IngredientRowWidget> {
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
            flex: 4,
            child: TextField(
              controller: widget.row.nameController,
              focusNode: widget.row.firstFocusNode,
              textInputAction: TextInputAction.next,
              decoration: buildBulkInputDecoration(context, 'Название сырья'),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Ед. изм.
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: widget.row.selectedUnit,
              decoration: buildBulkInputDecoration(context, 'Ед. изм.'),
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

          // 3. Закупка (Себестоимость)
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
      ),
    );
  }
}

