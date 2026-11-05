// ==============================================================================
// МОДУЛЬ: Склад / Шторка-корзина состава приходной накладной
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/dialogs/receive_document/
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'category_mode/receive_category_sync_adapter.dart';
import 'receipt_row_data.dart';

/// Всплывающая панель «Корзина накладной» со сквозным списком всех выбранных позиций.
class ReceiveDocumentCartSheet extends StatelessWidget {
  final List<ReceiptRowData> items;
  final ReceiveCategorySyncAdapter adapter;
  final String currency;
  final VoidCallback onClose;
  final VoidCallback onStateUpdate;

  const ReceiveDocumentCartSheet({
    super.key,
    required this.items,
    required this.adapter,
    required this.currency,
    required this.onClose,
    required this.onStateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validItems = items.where((r) => r.ingredient != null && r.quantity > 0).toList();

    double totalSum = 0.0;
    for (final it in validItems) {
      totalSum += it.quantity * it.price;
    }

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: validItems.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final item = validItems[index];
                      return _buildCartRow(context, item, isDark);
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
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text('Кол-во', style: style, textAlign: TextAlign.center)),
          const SizedBox(width: 14),
          SizedBox(width: 80, child: Text('Цена', style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 14),
          SizedBox(width: 85, child: Text('Сумма', style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 10),
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
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(PhosphorIconsRegular.shoppingCart, size: 20, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: 12),
          Text('Состав накладной', style: AppTextStyles.h2.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Text('$count поз.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
          ),
          const Spacer(),
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
          Text(
            'ИТОГО: ${totalSum.toCurrency(context)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkText : AppColors.lightText),
          ),
          AppSecondaryButton(
            label: 'Назад к накладной',
            size: AppButtonSize.sm,
            icon: PhosphorIconsRegular.arrowLeft,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildCartRow(BuildContext context, ReceiptRowData row, bool isDark) {
    final ing = row.ingredient!;
    final isRetail = ing.isRetail;
    final lineTotal = row.quantity * row.price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 1. Бейдж типа (Витрина / Сырьё)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isRetail
                  ? AppColors.brandPrimary.withValues(alpha: 0.12)
                  : AppColors.brandTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Text(
              isRetail ? 'Витрина' : 'Сырьё',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isRetail ? AppColors.brandPrimary : AppColors.brandTertiary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Наименование и единица
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ing.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Остаток: ${_fmt(ing.currentStock)} ${UnitFormatter.format(ing.unit)}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 3. Унифицированный счетчик количества из UI Kit
          AppQuantityStepper(
            value: row.quantity,
            allowDecimals: true,
            size: AppStepperSize.sm,
            unit: UnitFormatter.format(row.selectedUnit),
            min: 0,
            onChanged: (val) {
              final qty = val.toDouble();
              adapter.updateQuantity(ing, qty);
              row.qtyController.text = qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
              onStateUpdate();
            },
            onRemove: () {
              adapter.updateQuantity(ing, 0.0);
              row.qtyController.clear();
              onStateUpdate();
            },
          ),
          const SizedBox(width: 14),

          // 4. Цена закупки
          SizedBox(
            width: 80,
            child: Text('${row.price.toCurrency(context)}/ед', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ),
          const SizedBox(width: 14),

          // 5. Сумма строки
          SizedBox(
            width: 85,
            child: Text(lineTotal.toCurrency(context), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),

          // 6. Удаление позиции
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
            tooltip: 'Удалить из накладной',
            onPressed: () {
              adapter.updateQuantity(ing, 0.0);
              row.qtyController.clear();
              onStateUpdate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.shoppingCart, size: 36, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          const SizedBox(height: 10),
          Text('В накладной пока нет позиций', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 4),
          Text('Введите количество товаров в категориях или строках', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        ],
      ),
    );
  }

  String _fmt(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    final str = val.toStringAsFixed(3);
    final trimmed = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }
}
