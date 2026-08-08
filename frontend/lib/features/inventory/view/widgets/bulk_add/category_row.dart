import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/widgets/icon_picker_field.dart';
import 'bulk_input_decoration.dart';

class CategoryRowData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sortOrderController = TextEditingController();
  final FocusNode firstFocusNode = FocusNode();
  String? selectedIcon;

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

  const CategoryRowWidget({
    super.key,
    required this.row,
    required this.onAddRow,
  });

  @override
  State<CategoryRowWidget> createState() => _CategoryRowWidgetState();
}

class _CategoryRowWidgetState extends State<CategoryRowWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
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
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => widget.onAddRow(),
            decoration: buildBulkInputDecoration(context, 'Порядок'),
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }
}
