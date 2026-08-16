import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class MenuItemModifierGroupsSection extends StatelessWidget {
  final List<Map<String, dynamic>> modifierGroups;
  final VoidCallback onAddGroup;
  final Function(int index) onRemoveGroup;
  final Function(int groupIndex) onAddOption;
  final Function(int groupIndex, int optionIndex) onRemoveOption;
  final Function(int groupIndex, bool required) onToggleRequired;

  const MenuItemModifierGroupsSection({
    super.key,
    required this.modifierGroups,
    required this.onAddGroup,
    required this.onRemoveGroup,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onToggleRequired,
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
              'Группы модификаторов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onAddGroup,
              icon: const Icon(PhosphorIconsRegular.plus),
              label: const Text('Добавить группу'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...modifierGroups.asMap().entries.map((e) {
          final gIndex = e.key;
          final group = e.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: group['name'],
                          decoration: const InputDecoration(
                            labelText: 'Название группы (напр. Соусы)',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => group['name'] = v,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger),
                        onPressed: () => onRemoveGroup(gIndex),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Обязательно к выбору', style: TextStyle(fontSize: 14)),
                          value: group['required'] ?? false,
                          onChanged: (v) => onToggleRequired(gIndex, v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: (group['max_selections'] ?? 1).toString(),
                          decoration: const InputDecoration(
                            labelText: 'Макс. кол-во опций',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => group['max_selections'] = int.tryParse(v) ?? 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Опции:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...(group['modifiers'] as List).asMap().entries.map((me) {
                    final mIndex = me.key;
                    final mod = me.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: mod['name'],
                              decoration: const InputDecoration(
                                labelText: 'Опция',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => mod['name'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: mod['price'].toString(),
                              decoration: const InputDecoration(
                                labelText: 'Цена',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => mod['price'] = double.tryParse(v) ?? 0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.x, size: 18),
                            onPressed: () => onRemoveOption(gIndex, mIndex),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => onAddOption(gIndex),
                    icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                    label: const Text('Добавить опцию'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
