// ==============================================================================
// МОДУЛЬ: POS / Список позиций столика (PosActiveTableItemsView)
// ДОМЕН: lib/features/pos/view/widgets/tables/pos_active_table_items_view.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Компонент отображения позиций столика:
// 1. Поддерживает разделение на «Ранее подано» и «К готовке (дозаказ)».
// 2. Отображает наименование, количество и подытог позиции с форматированием валюты.
// 3. Использует дизайн-токены шрифтов, цветов и интервалов (AppSpacing, AppColors).
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';

// ── 1. Список позиций в активном заказе столика ──────────────────────────────

class PosActiveTableItemsView extends StatelessWidget {
  final bool hasDozakaz;
  final List<Map<String, dynamic>> servedItems;
  final List<Map<String, dynamic>> dozakazItems;
  final List<Map<String, dynamic>> cleanItems;
  final bool isDark;

  const PosActiveTableItemsView({
    super.key,
    required this.hasDozakaz,
    required this.servedItems,
    required this.dozakazItems,
    required this.cleanItems,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (hasDozakaz) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          if (servedItems.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.checkCircle,
                  size: 12,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                AppSpacing.hXxs,
                Text(
                  'Ранее подано:',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
            AppSpacing.vXxs,
            for (var it in servedItems) _buildRow(context, it, isDozakaz: false),
            AppSpacing.vSm,
          ],
          if (dozakazItems.isNotEmpty) ...[
            const Row(
              children: [
                Icon(PhosphorIconsBold.sparkle, size: 12, color: AppColors.warning),
                SizedBox(width: 4),
                Text(
                  'К готовке (новый дозаказ):',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            AppSpacing.vXxs,
            for (var it in dozakazItems) _buildRow(context, it, isDozakaz: true),
          ],
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: cleanItems.length,
      separatorBuilder: (_, __) => AppSpacing.vXxs,
      itemBuilder: (context, index) => _buildRow(context, cleanItems[index], isDozakaz: false),
    );
  }

  Widget _buildRow(BuildContext context, Map<String, dynamic> it, {required bool isDozakaz}) {
    final name = it['menu_item_name'] ?? '';
    final qty = it['quantity'] ?? 1;
    final sub = (it['subtotal'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$name × $qty',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isDozakaz ? FontWeight.w700 : FontWeight.w500,
                color: isDozakaz ? AppColors.warning : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.hSm,
          Text(
            sub.toCurrency(context),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isDozakaz ? FontWeight.w800 : FontWeight.w600,
              color: isDozakaz ? AppColors.warning : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ),
        ],
      ),
    );
  }
}
