// ==============================================================================
// МОДУЛЬ: Склад / Строка товара в списке остатков (Stock Item Row)
// ДОМЕН: lib/features/inventory/view/widgets/warehouse/stock/stock_item_row.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_motion.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import 'package:kreso_frontend/features/inventory/models/ingredient.dart';

/// [UI-KIT] Строка позиции склада с поддержкой hover, индикатора дефицита и 8pt-сетки
class StockItemRow extends StatefulWidget {
  final Ingredient item;
  final bool isLast;

  const StockItemRow({
    super.key,
    required this.item,
    this.isLast = false,
  });

  @override
  State<StockItemRow> createState() => _StockItemRowState();
}

class _StockItemRowState extends State<StockItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.item;
    final isLowStock = item.isLowStock;
    final isCritical = item.currentStock <= 0;

    // ── Цветовая индикация остатка ──
    Color stockColor = AppColors.success;
    if (isCritical) {
      stockColor = AppColors.danger;
    } else if (isLowStock) {
      stockColor = AppColors.warning;
    }

    final translatedUnit = UnitFormatter.format(item.unit);
    final borderSide = BorderSide(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      width: 0.8,
    );

    final bg = _isHovered
        ? (isDark ? AppColors.darkCardHover : AppColors.lightBg)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standardCurve,
        margin: EdgeInsets.only(bottom: widget.isLast ? 8 : 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: widget.isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg))
              : BorderRadius.zero,
          border: Border(
            left: borderSide,
            right: borderSide,
            bottom: borderSide,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () {
              // Детали позиции
            },
            borderRadius: widget.isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg))
                : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Единица измерения (Бейдж)
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBg,
                      borderRadius: AppRadii.inputRadius,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      translatedUnit,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 2. Название и характеристики
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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

                  // 3. Остаток и алерт минимального запаса
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
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: stockColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            'Мин: ${UnitFormatter.formatAmount(item.minStockAlert, item.unit)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Финансовые показатели
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
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          'Закуп: ${item.costPerUnit.toStringAsFixed(2)} с / $translatedUnit',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                        if (item.currentStock > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Σ: ${(item.currentStock * (item.price ?? item.costPerUnit)).toCurrency(context)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildAttributeChip(String label, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: AppRadii.radiusXs,
        border: Border.all(
          color: textColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
