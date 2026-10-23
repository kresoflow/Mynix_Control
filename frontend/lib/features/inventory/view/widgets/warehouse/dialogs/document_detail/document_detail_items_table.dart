import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/document.dart';
import 'document_detail_item_row.dart';

class DocumentDetailItemsTable extends StatelessWidget {
  final InventoryDocument doc;

  const DocumentDetailItemsTable({super.key, required this.doc});

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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'В документе нет позиций',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int index = 0; index < items.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                isInventory
                    ? DocumentDetailInventoryRow(
                        item: items[index],
                        index: index,
                        isDark: isDark,
                      )
                    : DocumentDetailStandardRow(
                        item: items[index],
                        index: index,
                        isDark: isDark,
                      ),
              ],
            ],
          ),
        const SizedBox(height: 6),
        _buildSummary(context, items, isDark, isInventory, totalDiscrepancy),
      ],
    );
  }

  Widget _buildHeader(bool isDark, bool isInventory) {
    final colStyle = AppTextStyles.caption.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
    );
    final headerStyle = AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: isDark ? AppColors.darkSurface : AppColors.lightCardHover,
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('№', style: colStyle)),
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

  Widget _buildSummary(BuildContext context, List<InventoryDocumentItem> items, bool isDark, bool isInventory, double totalDiscrepancy) {
    final isWriteOff = doc.type == 'write_off';
    final isReceipt = doc.type == 'receipt';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.radiusLg,
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
                  borderRadius: AppRadii.badgeRadius,
                ),
                child: Text(
                  '${items.length} поз.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandPrimary,
                  ),
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
