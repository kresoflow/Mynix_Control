// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'write_off_items_table.dart';

// ==============================================================================
// 2. ВСПЛЫВАЮЩАЯ ШТОРКА КОРЗИНЫ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Шторка-корзина со сводным списком позиций акта списания.
class WriteOffCartSheet extends StatelessWidget {
  final List<WriteOffItemEntry> items;
  final String currency;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;
  final VoidCallback onClose;

  const WriteOffCartSheet({
    super.key,
    required this.items,
    required this.currency,
    required this.onRemove,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validItems = items.where((e) => e.quantity > 0).toList();
    final totalSum = validItems.fold(0.0, (sum, e) => sum + e.total);

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          _buildHeader(context, isDark, validItems.length),
          _buildTableHeader(isDark),
          Expanded(
            child: validItems.isEmpty
                ? _buildEmpty(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: validItems.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : AppColors.lightBorder.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final entry = validItems[index];
                      final actualIndex = items.indexOf(entry);
                      return _buildCartRow(context, entry, actualIndex, isDark);
                    },
                  ),
          ),
          _buildFooter(context, isDark, validItems.length, totalSum),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    final style = AppTextStyles.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pureWhite.withValues(alpha: 0.03) : AppColors.pureBlack.withValues(alpha: 0.03),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Expanded(child: Text('Номенклатура', style: style)),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text('К списанию', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 10),
          SizedBox(width: 75, child: Text('Себест.', style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text('Сумма', style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 8),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.xs)),
            child: const Icon(PhosphorIconsRegular.shoppingCart, size: 20, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text('Состав акта списания', style: AppTextStyles.h2.copyWith(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.xs)),
                  child: Text('$count поз.', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(PhosphorIconsRegular.x, size: 18), tooltip: 'Закрыть', onPressed: onClose),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, int count, double totalSum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('ИТОГО: ${totalSum.toStringAsFixed(2)} $currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? AppColors.pureWhite : AppColors.darkBg)),
          AppSecondaryButton(
            label: 'Назад к акту',
            size: AppButtonSize.sm,
            icon: PhosphorIconsRegular.arrowLeft,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildCartRow(BuildContext context, WriteOffItemEntry entry, int index, bool isDark) {
    final ing = entry.item;
    final isRetail = ing.isRetail;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isRetail ? AppColors.brandPrimary.withValues(alpha: 0.12) : AppColors.brandTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Text(isRetail ? 'Витрина' : 'Сырьё', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isRetail ? AppColors.brandPrimary : AppColors.brandTertiary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(ing.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          AppQuantityStepper(
            value: entry.quantity,
            allowDecimals: true,
            size: AppStepperSize.sm,
            unit: UnitFormatter.format(ing.unit),
            min: 0,
            onChanged: (val) {
              final qty = val.toDouble();
              entry.quantity = qty;
              entry.controller.text = qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
              onChanged();
            },
            onRemove: () => onRemove(index),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 75, child: Text('${entry.cost.toStringAsFixed(2)} $currency', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: subColor))),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text('${entry.total.toStringAsFixed(2)} $currency', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger), tooltip: 'Удалить из списания', onPressed: () => onRemove(index)),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.tray, size: 40, color: subColor),
          const SizedBox(height: 8),
          Text('Нет позиций для списания', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: subColor)),
        ],
      ),
    );
  }
}
