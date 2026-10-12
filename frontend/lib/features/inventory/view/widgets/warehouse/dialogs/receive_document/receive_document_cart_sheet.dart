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
import 'package:kreso_frontend/features/inventory/view/widgets/bulk_add/bulk_input_decoration.dart';
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

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.58,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(context, isDark, validItems.length, totalSum),
              const Divider(height: 1),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int count, double totalSum) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(PhosphorIconsRegular.shoppingCart, size: 20, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: 12),
          Text('Состав накладной', style: AppTextStyles.h2.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Text('$count поз.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
          ),
          const Spacer(),
          Text('Σ ${totalSum.toCurrency(context)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(PhosphorIconsRegular.x, size: 18), tooltip: 'Закрыть', onPressed: onClose),
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
              borderRadius: BorderRadius.circular(6),
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

          // 3. Поле количества
          SizedBox(
            width: 75,
            height: 32,
            child: TextField(
              controller: row.qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              decoration: buildBulkInputDecoration(context, '0', isHintOnly: true, contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6)),
              onChanged: (val) {
                final qty = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                adapter.updateQuantity(ing, qty);
                onStateUpdate();
              },
            ),
          ),
          const SizedBox(width: 6),
          Text(UnitFormatter.format(row.selectedUnit), style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(width: 14),

          // 4. Цена закупки
          SizedBox(
            width: 90,
            child: Text('${row.price.toCurrency(context)}/ед', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ),
          const SizedBox(width: 14),

          // 5. Сумма строки
          SizedBox(
            width: 90,
            child: Text(lineTotal.toCurrency(context), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),

          // 6. Удаление позиции
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash, size: 16, color: AppColors.danger),
            tooltip: 'Удалить из накладной',
            onPressed: () {
              adapter.updateQuantity(ing, 0.0);
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
