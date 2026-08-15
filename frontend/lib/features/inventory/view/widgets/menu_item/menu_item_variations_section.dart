import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class MenuItemVariationsSection extends StatelessWidget {
  final List<Map<String, dynamic>> variations;
  final VoidCallback onAddVariation;
  final Function(int index) onRemoveVariation;

  const MenuItemVariationsSection({
    super.key,
    required this.variations,
    required this.onAddVariation,
    required this.onRemoveVariation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Вариации (Размеры)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onAddVariation,
              icon: const Icon(PhosphorIconsRegular.plus),
              label: const Text('Добавить размер'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...variations.asMap().entries.map((e) {
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: variations[i]['name'],
                    decoration: const InputDecoration(
                      labelText: 'Название (напр. Стандарт)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => variations[i]['name'] = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: variations[i]['price'].toString(),
                    decoration: const InputDecoration(
                      labelText: 'Цена',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => variations[i]['price'] = double.tryParse(v) ?? 0,
                  ),
                ),
                IconButton(
                  icon: Icon(PhosphorIconsRegular.trash, color: AppColors.danger),
                  onPressed: () => onRemoveVariation(i),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
