import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/inventory/models/document.dart';

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
      for (var it in items) {
        final exp = it.expectedQuantity ?? it.quantity;
        final diff = it.quantity - exp;
        totalDiscrepancy += (diff * it.pricePerUnit);
      }
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          child: Row(
            children: [
              const SizedBox(width: 30, child: Text('№', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
              Expanded(
                flex: 4,
                child: Text('Наименование', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (isInventory) ...[
                Expanded(
                  flex: 2,
                  child: Text('Учет (было)', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Факт (стало)', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Отклонение', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                Expanded(
                  flex: 2,
                  child: Text('Кол-во', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Цена', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Сумма', textAlign: TextAlign.right, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Items List
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
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final name = item.ingredientName ?? item.retailProductName ?? 'Позиция #${item.id ?? index + 1}';

              if (isInventory) {
                final exp = item.expectedQuantity ?? item.quantity;
                final fact = item.quantity;
                final diff = fact - exp;
                final diffAmount = diff * item.pricePerUnit;
                final bool isSurplus = diff > 0.001;
                final bool isShortage = diff < -0.001;

                final diffColor = isSurplus ? AppColors.success : (isShortage ? AppColors.danger : Colors.grey);
                final diffText = isSurplus
                    ? '+${diff.toStringAsFixed(2)} (+${diffAmount.toStringAsFixed(0)} с)'
                    : (isShortage ? '${diff.toStringAsFixed(2)} (${diffAmount.toStringAsFixed(0)} с)' : '0.00 (0 с)');

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
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
                          exp.toStringAsFixed(exp.truncateToDouble() == exp ? 0 : 2),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          fact.toStringAsFixed(fact.truncateToDouble() == fact ? 0 : 2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: diffColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
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
                        item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.pricePerUnit.toCurrency(context),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.caption,
                      ),
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
            },
          ),

        const SizedBox(height: 6),

        // Total Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.type == 'receipt'
                        ? 'ИТОГО К ОПЛАТЕ:'
                        : (doc.type == 'write_off' ? 'ИТОГО СПИСАНИЕ:' : 'СТОИМОСТЬ ОСТАТКОВ ПО ФАКТУ:'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isInventory) ...[
                    const SizedBox(height: 2),
                    Text(
                      totalDiscrepancy < -0.01
                          ? '🔴 Итоговая недостача ревизии: ${totalDiscrepancy.toStringAsFixed(2)} с'
                          : (totalDiscrepancy > 0.01
                              ? '🟢 Итоговый излишек ревизии: +${totalDiscrepancy.toStringAsFixed(2)} с'
                              : '✅ Отклонений нет — факт совпадает с учетом'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: totalDiscrepancy < -0.01
                            ? AppColors.danger
                            : (totalDiscrepancy > 0.01 ? AppColors.success : AppColors.brandPrimary),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                doc.totalAmount.toCurrency(context),
                style: AppTextStyles.h2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: doc.type == 'write_off' ? AppColors.danger : AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
