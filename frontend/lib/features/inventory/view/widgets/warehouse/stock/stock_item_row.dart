import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';

class StockItemRow extends StatelessWidget {
  final Ingredient item;
  final bool isLast;

  const StockItemRow({super.key, required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = item.isLowStock;
    final isCritical = item.currentStock <= 0;

    // Индикатор цвета
    Color stockColor = AppColors.success;
    if (isCritical) {
      stockColor = AppColors.danger;
    } else if (isLowStock) {
      stockColor = AppColors.warning;
    }

    final translatedUnit = UnitFormatter.format(item.unit);

    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 12 : 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: isLast 
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : BorderRadius.zero,
        border: Border(
          left: borderSide,
          right: borderSide,
          bottom: borderSide,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Открыть детали товара
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Единица измерения (Бейдж)
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    translatedUnit,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Название и Категория (Точка входа взгляда)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      if (item.attributes != null &&
                          (item.attributes!['flavor'] != null || item.attributes!['volume'] != null)) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (item.attributes!['flavor'] != null &&
                                item.attributes!['flavor'].toString().isNotEmpty &&
                                !item.name.toLowerCase().contains(item.attributes!['flavor'].toString().toLowerCase()))
                              _buildAttributeChip(
                                item.attributes!['flavor'].toString(),
                                AppColors.warning,
                                isDark,
                              ),
                            if (item.attributes!['volume'] != null &&
                                item.attributes!['volume'].toString().isNotEmpty &&
                                !item.name.toLowerCase().contains(item.attributes!['volume'].toString().toLowerCase()))
                              _buildAttributeChip(
                                item.attributes!['volume'].toString(),
                                AppColors.info,
                                isDark,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // 3. Остаток (Фокус)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: stockColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            UnitFormatter.formatAmount(item.currentStock, item.unit),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          'Мин: ${UnitFormatter.formatAmount(item.minStockAlert, item.unit)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Финансы (Правый край)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.price != null && item.price! > 0) ...[
                        Text(
                          'Розница: ${item.price!.toCurrency(context)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        'Закуп: ${item.costPerUnit.toStringAsFixed(2)} с / $translatedUnit',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                      if (item.currentStock > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Σ: ${(item.currentStock * (item.price ?? item.costPerUnit)).toCurrency(context)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeChip(String label, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: textColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
