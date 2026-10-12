// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'write_off_item_row.dart';

// ==============================================================================
// 2. МОДЕЛЬ СТРОКИ СПИСАНИЯ
// ==============================================================================
class WriteOffItemEntry {
  final Ingredient item;
  double quantity;
  final TextEditingController controller;

  WriteOffItemEntry({
    required this.item,
    required this.quantity,
  }) : controller = TextEditingController(
          text: quantity > 0
              ? (quantity == quantity.truncateToDouble()
                  ? quantity.toInt().toString()
                  : quantity.toString())
              : '',
        );

  double get cost => item.costPerUnit;
  double get total => quantity * cost;
}

// ==============================================================================
// 3. ТАБЛИЦА ПОЗИЦИЙ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Строгая табулярная таблица списания склада с выравниванием колонок.
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

  static const double colNumWidth = 32.0;
  static const double colStockWidth = 85.0;
  static const double colQtyWidth = 85.0;
  static const double colCostWidth = 105.0;
  static const double colTotalWidth = 100.0;
  static const double colActionWidth = 36.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isDark),
          if (items.isEmpty)
            _buildEmptyState(isDark)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                itemBuilder: (context, index) => WriteOffItemRow(
                  entry: items[index],
                  index: index,
                  currency: currency,
                  onRemove: onRemove,
                  onChanged: onChanged,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final hStyle = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 11,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: colNumWidth,
            child: Text(
              '№',
              textAlign: TextAlign.center,
              style: hStyle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('Наименование', style: hStyle)),
          const SizedBox(width: 8),
          SizedBox(
            width: colStockWidth,
            child: Text('Остаток', textAlign: TextAlign.right, style: hStyle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: colQtyWidth,
            child:
                Text('К списанию', textAlign: TextAlign.center, style: hStyle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: colCostWidth,
            child: Text(
              'Себестоимость',
              textAlign: TextAlign.right,
              style: hStyle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: colTotalWidth,
            child: Text('Сумма', textAlign: TextAlign.right, style: hStyle),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: colActionWidth),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.archive,
            size: 32,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
          const SizedBox(height: 8),
          Text(
            'Позиции для списания не добавлены',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Используйте строку поиска или перейдите в каталог по категориям',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
