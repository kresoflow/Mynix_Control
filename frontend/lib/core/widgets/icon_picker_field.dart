import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/utils/icon_helper.dart';

class IconPickerField extends StatelessWidget {
  final String? selectedIcon;
  final Function(String) onIconSelected;
  final InputDecoration? decoration;

  const IconPickerField({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the initially selected icon exists in the list (or is empty)
    final initial = (selectedIcon == null || selectedIcon!.isEmpty) ? '' : selectedIcon!;
    final available = IconHelper.availableIcons;
    final valueToUse = (initial.isNotEmpty && !available.contains(initial)) ? '' : initial;

    return DropdownButtonFormField<String>(
      initialValue: valueToUse,
      decoration: decoration ?? const InputDecoration(labelText: 'Иконка (на кассе)'),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: '', child: Text('Без иконки (по умолчанию)')),
        ...available.map((iconName) {
          return DropdownMenuItem(
            value: iconName,
            child: Row(
              children: [
                IconHelper.buildIcon(iconName, size: 24, color: Theme.of(context).iconTheme.color),
                const SizedBox(width: 12),
                Expanded(child: Text(iconName, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        }),
      ],
      onChanged: (val) {
        if (val != null) onIconSelected(val);
      },
    );
  }
}
