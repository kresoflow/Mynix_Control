import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

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

  String _fmt(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isDark),
          if (items.isEmpty)
            _buildEmptyState(isDark)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                itemBuilder: (context, index) => _buildRow(context, items[index], index, isDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final hStyle = AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 26, child: Text('№', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 4, child: Text('Наименование', style: hStyle)),
          Expanded(flex: 2, child: Text('Остаток', textAlign: TextAlign.right, style: hStyle)),
          Expanded(flex: 2, child: Text('К списанию', textAlign: TextAlign.right, style: hStyle)),
          Expanded(flex: 2, child: Text('Себест-сть', textAlign: TextAlign.right, style: hStyle)),
          Expanded(flex: 2, child: Text('Сумма', textAlign: TextAlign.right, style: hStyle)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.archive, size: 32, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          const SizedBox(height: 8),
          Text(
            'Позиции для списания не добавлены',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText),
          ),
          const SizedBox(height: 4),
          Text(
            'Используйте строку поиска выше, чтобы найти и добавить товары',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, WriteOffItemEntry entry, int index, bool isDark) {
    final unit = UnitFormatter.format(entry.item.unit);
    final isStockLow = entry.item.currentStock < entry.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 26, child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                if (isStockLow)
                  const Text('Превышает остаток!', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_fmt(entry.item.currentStock)} $unit',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: entry.controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: unit,
                  suffixStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onChanged: (val) {
                  entry.quantity = double.tryParse(val) ?? 0.0;
                  onChanged();
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${entry.cost.toStringAsFixed(2)} $currency', textAlign: TextAlign.right, style: AppTextStyles.caption),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${entry.total.toStringAsFixed(2)} $currency',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            tooltip: 'Удалить строку',
            onPressed: () => onRemove(index),
          ),
        ],
      ),
    );
  }
}
