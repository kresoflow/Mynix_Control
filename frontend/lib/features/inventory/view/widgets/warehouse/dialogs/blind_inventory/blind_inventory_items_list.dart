import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

class BlindInventoryItemsList extends StatelessWidget {
  final List<Ingredient> items;
  final Map<int, TextEditingController> controllers;
  final VoidCallback onChanged;

  const BlindInventoryItemsList({
    super.key,
    required this.items,
    required this.controllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Позиции не найдены',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          if (!controllers.containsKey(item.id)) {
            controllers[item.id] = TextEditingController();
          }
          final unit = UnitFormatter.format(item.unit);
          final isRetail = item.attributes?['is_retail'] == true;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color:
                              isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRetail ? 'Витрина' : 'Сырье',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 36,
                  child: TextField(
                    controller: controllers[item.id],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Факт',
                      suffixText: unit,
                      suffixStyle: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
