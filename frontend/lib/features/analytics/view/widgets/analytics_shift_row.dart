import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

class AnalyticsShiftRow extends StatelessWidget {
  final Map<String, dynamic> shift;

  const AnalyticsShiftRow({
    super.key,
    required this.shift,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shiftId = shift['id'];
    final isOpen = shift['is_open'] == true;
    final totalRev = (shift['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final diff = (shift['discrepancy'] as num?)?.toDouble();
    final openingCash = (shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = shift['orders_count'] ?? 0;

    String openedStr = '-';
    if (shift['opened_at'] != null) {
      final p = DateTime.tryParse(shift['opened_at'].toString());
      if (p != null) openedStr = DateFormat('dd.MM.yyyy, HH:mm').format(p.toLocal());
    }

    String closedStr = '-';
    if (shift['closed_at'] != null) {
      final p = DateTime.tryParse(shift['closed_at'].toString());
      if (p != null) closedStr = DateFormat('HH:mm').format(p.toLocal());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.success.withValues(alpha: 0.12) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isOpen ? AppColors.success.withValues(alpha: 0.3) : Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$shiftId',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.success : AppColors.darkSubtext,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'Смена активна' : 'Смена закрыта',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOpen ? 'Открыта: $openedStr' : 'Открыта: $openedStr  →  Закрыта: $closedStr',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Размен / Чеков:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                const SizedBox(height: 2),
                Text('${openingCash.toCurrency(context)} • $ordersCount шт.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Выручка смены:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                const SizedBox(height: 2),
                Text(totalRev.toCurrency(context), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
              ],
            ),
          ),
          if (!isOpen && diff != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: diff == 0
                    ? AppColors.success.withValues(alpha: 0.1)
                    : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                ),
              ),
              child: Text(
                diff == 0 ? '✓ Точно (0 с)' : (diff < 0 ? 'Недостача: ${diff.toCurrency(context)}' : 'Излишек: +${diff.toCurrency(context)}'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
