import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RetailVariationsEditor extends StatelessWidget {
  final TextEditingController flavorController;
  final List<Map<String, dynamic>> variations;
  final Map<String, String> units;
  final VoidCallback onAddVariation;
  final ValueChanged<int> onRemoveVariation;
  final VoidCallback onStateChanged;

  const RetailVariationsEditor({
    super.key,
    required this.flavorController,
    required this.variations,
    required this.units,
    required this.onAddVariation,
    required this.onRemoveVariation,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: flavorController,
          decoration: const InputDecoration(
            labelText: 'Вкус / Описание группы (необязательно)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Опции (Объемы / Вариации)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: ListView.builder(
            itemCount: variations.length,
            itemBuilder: (context, i) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: variations[i]['name'],
                              decoration: const InputDecoration(labelText: 'Опция (напр. 0.5л)', isDense: true),
                              onChanged: (v) {
                                variations[i]['name'] = v;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(isDense: true),
                              initialValue: variations[i]['unit'],
                              items: units.entries
                                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                  .toList(),
                              onChanged: (val) {
                                variations[i]['unit'] = val;
                                onStateChanged();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                            onPressed: () => onRemoveVariation(i),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: variations[i]['purchasePrice'].toString(),
                              decoration: const InputDecoration(labelText: 'Закупка', prefixText: 'TJS ', isDense: true),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                variations[i]['purchasePrice'] = double.tryParse(v) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: variations[i]['price'].toString(),
                              decoration: const InputDecoration(labelText: 'Продажа', prefixText: 'TJS ', isDense: true),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                variations[i]['price'] = double.tryParse(v) ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: variations[i]['stock'].toString(),
                              decoration: const InputDecoration(labelText: 'Нач. остаток', isDense: true),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                variations[i]['stock'] = double.tryParse(v) ?? 0;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: variations[i]['barcode'],
                              decoration: InputDecoration(
                                labelText: 'Штрихкод',
                                isDense: true,
                                prefixIcon: Icon(PhosphorIconsRegular.barcode, color: AppColors.brandPrimary),
                              ),
                              onChanged: (v) {
                                variations[i]['barcode'] = v;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        TextButton.icon(
          icon: const Icon(PhosphorIconsRegular.plus),
          label: const Text('Добавить опцию'),
          onPressed: onAddVariation,
        ),
      ],
    );
  }
}
