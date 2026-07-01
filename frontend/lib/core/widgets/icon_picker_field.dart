import 'package:flutter/material.dart';

class IconPickerField extends StatelessWidget {
  final String? selectedIcon;
  final Function(String) onIconSelected;

  const IconPickerField({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedIcon ?? 'pizza',
      decoration: const InputDecoration(labelText: 'Иконка'),
      items: const [
        DropdownMenuItem(value: 'pizza', child: Text('Пицца')),
        DropdownMenuItem(value: 'coffee', child: Text('Кофе')),
        DropdownMenuItem(value: 'hamburger', child: Text('Бургер')),
        DropdownMenuItem(value: 'bowlFood', child: Text('Суп')),
      ],
      onChanged: (val) {
        if (val != null) onIconSelected(val);
      },
    );
  }
}
