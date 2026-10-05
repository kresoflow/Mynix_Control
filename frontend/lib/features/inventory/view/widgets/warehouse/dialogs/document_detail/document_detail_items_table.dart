import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';

class DocumentDetailItemsTable extends StatelessWidget {
  final InventoryDocument doc;

  const DocumentDetailItemsTable({super.key, required this.doc});

  String _fmt(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = doc.items ?? [];
    final isInventory = doc.type == 'inventory';

    double totalDiscrepancy = 0.0;
    if (isInventory) {
      for (final it in items) {
        final exp = it.expectedQuantity ?? it.quantity;
        totalDiscrepancy += (it.quantity - exp) * it.pricePerUnit;
      }
    }

    return Column(
      children: [
        _buildHeader(isDark, isInventory),
        const SizedBox(height: 4),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('В документе нет позиций', style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return isInventory
                  ? _buildInventoryRow(context, item, index, isDark)
                  : _buildStandardRow(context, item, index, isDark);
            },
          ),
        const SizedBox(height: 6),
        _buildSummary(context, items, isDark, isInventory, totalDiscrepancy),
      ],
    );
  }

  Widget _buildHeader(bool isDark, bool isInventory) {
    const colStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey);
    final headerStyle = AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
      child: Row(
        children: [
          const SizedBox(width: 30, child: Text('№', style: colStyle)),
          Expanded(flex: 4, child: Text('Наименование', style: headerStyle)),
          if (isInventory) ...[
            Expanded(flex: 2, child: Text('Учет (было)', textAlign: TextAlign.right, style: headerStyle)),
            Expanded(flex: 2, child: Text('Факт (стало)', textAlign: TextAlign.right, style: headerStyle)),
            Expanded(flex: 3, child: Text('Отклонение', textAlign: TextAlign.right, style: headerStyle)),
          ] else ...[
            Expanded(flex: 2, child: Text('Кол-во', textAlign: TextAlign.right, style: headerStyle)),
            Expanded(flex: 2, child: Text('Цена', textAlign: TextAlign.right, style: headerStyle)),
            Expanded(flex: 2, child: Text('Сумма', textAlign: TextAlign.right, style: headerStyle)),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryRow(BuildContext context, InventoryDocumentItem item, int index, bool isDark) {
    final name = item.ingredientName ?? item.retailProductName ?? 'Позиция #${item.id ?? index + 1}';
    final exp = item.expectedQuantity ?? item.quantity;
    final diff = item.quantity - exp;
    final diffAmount = diff * item.pricePerUnit;
    final isSurplus = diff > 0.001;
    final isShortage = diff < -0.001;

    final diffColor = isSurplus ? AppColors.success : (isShortage ? AppColors.danger : Colors.grey);
    final diffText = isSurplus
        ? '+${_fmt(diff)} (+${diffAmount.toStringAsFixed(0)} с)'
        : (isShortage ? '${_fmt(diff)} (${diffAmount.toStringAsFixed(0)} с)' : '0.00 (0 с)');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmt(exp),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmt(item.quantity), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  diffText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: diffColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardRow(BuildContext context, InventoryDocumentItem item, int index, bool isDark) {
    final name = item.ingredientName ?? item.retailProductName ?? 'Позиция #${item.id ?? index + 1}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmt(item.quantity), textAlign: TextAlign.right, style: AppTextStyles.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: Text(item.pricePerUnit.toCurrency(context), textAlign: TextAlign.right, style: AppTextStyles.caption),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.totalPrice.toCurrency(context),
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, List<InventoryDocumentItem> items, bool isDark, bool isInventory, double totalDiscrepancy) {
    final isWriteOff = doc.type == 'write_off';
    final isReceipt = doc.type == 'receipt';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${items.length} поз.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Всего: ${items.fold(0.0, (sum, it) => sum + it.quantity).toStringAsFixed(0)} шт.',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isReceipt
                    ? 'ИТОГО К ОПЛАТЕ: '
                    : (isWriteOff ? 'ИТОГО СПИСАНИЕ: ' : (isInventory ? 'РАСХОЖДЕНИЕ: ' : 'ИТОГО: ')),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              Text(
                isInventory
                    ? '${totalDiscrepancy >= 0 ? '+' : ''}${totalDiscrepancy.toCurrency(context)}'
                    : doc.totalAmount.toCurrency(context),
                style: AppTextStyles.h2.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isWriteOff
                      ? AppColors.danger
                      : (isInventory
                          ? (totalDiscrepancy > 0
                              ? AppColors.success
                              : (totalDiscrepancy < 0 ? AppColors.danger : AppColors.brandPrimary))
                          : AppColors.brandPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
