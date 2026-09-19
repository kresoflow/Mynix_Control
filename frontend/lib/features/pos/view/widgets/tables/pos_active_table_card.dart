import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';

class PosActiveTableCard extends StatelessWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback onDozakaz;
  final VoidCallback onSplit;
  final VoidCallback onSettle;
  final VoidCallback? onMarkServed;
  final bool isDark;

  const PosActiveTableCard({
    super.key,
    required this.tableData,
    required this.onDozakaz,
    required this.onSplit,
    required this.onSettle,
    this.onMarkServed,
    required this.isDark,
  });

  Color _getTimerColor(int minutes) {
    if (minutes >= 45) return AppColors.danger;
    if (minutes >= 30) return AppColors.warning;
    return AppColors.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final tableNumber = tableData['table_number']?.toString() ?? 'Стол';
    final orderNumber = tableData['order_number'] ?? 0;
    final total = (tableData['total'] as num?)?.toDouble() ?? 0.0;
    final elapsedMinutes = tableData['elapsed_minutes'] as int? ?? 0;
    final status = tableData['status']?.toString().toLowerCase() ?? '';
    final hasDozakaz = tableData['has_dozakaz'] == true;
    final isServed = status == 'ready' && !hasDozakaz;
    final servedItems = (tableData['served_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final dozakazItems = (tableData['dozakaz_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final cleanItems = (tableData['clean_items'] as List?)?.cast<Map<String, dynamic>>() ??
        (tableData['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final timerColor = isServed ? (isDark ? AppColors.darkSubtext : AppColors.lightSubtext) : _getTimerColor(elapsedMinutes);

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDozakaz
              ? AppColors.warning.withValues(alpha: 0.8)
              : (!isServed && elapsedMinutes >= 35 ? timerColor.withValues(alpha: 0.6) : border),
          width: (hasDozakaz || (!isServed && elapsedMinutes >= 35)) ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIconsBold.chair, color: AppColors.brandPrimary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tableNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    Text(
                      'Заказ #$orderNumber',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
              // Timer Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: timerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.clock, size: 12, color: timerColor),
                    const SizedBox(width: 4),
                    Text(
                      '$elapsedMinutes мин',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: timerColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Served Status / 1-Click Action Button
              if (isServed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsBold.checkCircle, size: 12, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Подано',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: onMarkServed,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.brandTertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.brandTertiary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      hasDozakaz ? 'Отдать дозаказ' : 'Отдать в зал',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: border, height: 1),
          const SizedBox(height: 8),

          Expanded(
            child: hasDozakaz
                ? ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (servedItems.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(PhosphorIconsRegular.checkCircle, size: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                            const SizedBox(width: 4),
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
                        const SizedBox(height: 4),
                        for (var it in servedItems) _buildItemRow(context, it, isDark, isDozakaz: false),
                        const SizedBox(height: 8),
                      ],
                      if (dozakazItems.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(PhosphorIconsBold.sparkle, size: 12, color: AppColors.warning),
                            const SizedBox(width: 4),
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
                        const SizedBox(height: 4),
                        for (var it in dozakazItems) _buildItemRow(context, it, isDark, isDozakaz: true),
                      ],
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: cleanItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) => _buildItemRow(context, cleanItems[index], isDark, isDozakaz: false),
                  ),
          ),
          const SizedBox(height: 8),
          Divider(color: border, height: 1),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'К оплате:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
              Text(
                total.toCurrency(context),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: onDozakaz,
                  icon: const Icon(PhosphorIconsBold.plus, size: 12),
                  label: const Text('Дозаказ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: onSplit,
                  icon: Icon(PhosphorIconsBold.scissors, size: 12, color: AppColors.warning),
                  label: Text('Сплит', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: AppColors.warning,
                    side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: onSettle,
                  icon: const Icon(PhosphorIconsBold.creditCard, size: 13),
                  label: const Text('Оплатить', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, Map<String, dynamic> it, bool isDark, {required bool isDozakaz}) {
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
          const SizedBox(width: 8),
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

