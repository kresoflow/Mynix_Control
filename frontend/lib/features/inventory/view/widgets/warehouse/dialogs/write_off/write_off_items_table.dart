import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/models/ingredient.dart';

class WriteOffItemEntry {
  final Ingredient item;
  double quantity;
  final TextEditingController controller;

  WriteOffItemEntry({
    required this.item,
    required this.quantity,
  }) : controller = TextEditingController(text: quantity > 0 ? quantity.toString() : '');

  double get cost => item.costPerUnit;
  double get total => quantity * cost;
}

class WriteOffItemsTable extends StatelessWidget {
  final List<WriteOffItemEntry> items;
  final String currency;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  const WriteOffItemsTable({
    super.key,
    required this.items,
    required this.currency,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Text(
          'Добавьте позиции для списания через поиск выше',
          style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        itemBuilder: (context, index) {
          final entry = items[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        'Остаток: ${entry.item.currentStock} ${entry.item.unit} • ${entry.cost.toStringAsFixed(2)} $currency/${entry.item.unit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: entry.controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Кол-во',
                      suffixText: entry.item.unit,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onChanged: (val) {
                      entry.quantity = double.tryParse(val) ?? 0.0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 90,
                  child: Text(
                    '${entry.total.toStringAsFixed(2)} $currency',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
                  onPressed: () => onRemove(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
