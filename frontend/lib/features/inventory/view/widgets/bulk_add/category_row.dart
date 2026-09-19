import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kreso_frontend/core/widgets/icon_picker_field.dart';
import 'bulk_input_decoration.dart';

class CategoryRowData {
  final String id;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sortOrderController = TextEditingController();
  final FocusNode firstFocusNode = FocusNode();
  String? selectedIcon;

  CategoryRowData({String? id}) : id = id ?? UniqueKey().toString();

  CategoryRowData clone() {
    return CategoryRowData()
      ..nameController.text = nameController.text
      ..sortOrderController.text = sortOrderController.text
      ..selectedIcon = selectedIcon;
  }
}

class CategoryRowWidget extends StatefulWidget {
  final CategoryRowData row;
  final VoidCallback onAddRow;
  final VoidCallback? onFocusPrevRow;
  final VoidCallback? onFocusNextRow;

  const CategoryRowWidget({
    super.key,
    required this.row,
    required this.onAddRow,
    this.onFocusPrevRow,
    this.onFocusNextRow,
  });

  @override
  State<CategoryRowWidget> createState() => _CategoryRowWidgetState();
}

class _CategoryRowWidgetState extends State<CategoryRowWidget> {
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
          // Name Field
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: widget.row.nameController,
              focusNode: widget.row.firstFocusNode,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => widget.onAddRow(),
              decoration: buildBulkInputDecoration(context, 'Название папки'),
            ),
          ),
          const SizedBox(width: 8),
          // Icon Picker
          Expanded(
            flex: 2,
            child: IconPickerField(
              selectedIcon: widget.row.selectedIcon,
              onIconSelected: (val) {
                setState(() {
                  widget.row.selectedIcon = val;
                });
              },
              decoration: buildBulkInputDecoration(context, 'Иконка (необяз.)'),
            ),
          ),
          const SizedBox(width: 8),
          // Sort Order Field
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: widget.row.sortOrderController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => widget.onAddRow(),
              decoration: buildBulkInputDecoration(context, 'Порядок'),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
