import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'dialogs/shift_history_details_dialog.dart';

class AnalyticsShiftRow extends StatefulWidget {
  final Map<String, dynamic> shift;

  const AnalyticsShiftRow({super.key, required this.shift});

  @override
  State<AnalyticsShiftRow> createState() => _AnalyticsShiftRowState();
}

class _AnalyticsShiftRowState extends State<AnalyticsShiftRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shift = widget.shift;
    final shiftId = shift['id'];
    final isOpen = shift['is_open'] == true;
    final totalRev = (shift['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final diff = (shift['discrepancy'] as num?)?.toDouble();
    final openingCash = (shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = shift['orders_count'] ?? 0;
    final itemsCount = shift['items_sold_count'] ?? 0;
    final openedBy = shift['opened_by_name'] ?? 'Кассир';

    String openedStr = '-';
    if (shift['opened_at'] != null) {
      final p = DateTime.tryParse(shift['opened_at'].toString());
      if (p != null) openedStr = DateFormat('dd.MM, HH:mm').format(p.toLocal());
    }

    String closedStr = '-';
    if (shift['closed_at'] != null) {
      final p = DateTime.tryParse(shift['closed_at'].toString());
      if (p != null) closedStr = DateFormat('dd.MM, HH:mm').format(p.toLocal());
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ShiftHistoryDetailsDialog.show(context, shift),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF1B2232) : const Color(0xFFF1F5F9))
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? AppColors.brandPrimary.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar Badge: 38px
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOpen
                        ? AppColors.success.withValues(alpha: 0.5)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$shiftId',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isOpen ? AppColors.success : (isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                ),
              ),
              const SizedBox(width: 14), // 38 + 14 = 52px

              // Shift & Cashier Column: flex: 4
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOpen ? AppColors.success : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          openedBy,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOpen ? 'Открыта: $openedStr (Активна)' : '$openedStr → $closedStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),

              // Float & Sales Column: flex: 3
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${openingCash.toCurrency(context)} размен',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$ordersCount заказов • $itemsCount поз.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),

              // Revenue Column: flex: 2
              Expanded(
                flex: 2,
                child: Text(
                  totalRev.toCurrency(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),

              // Discrepancy Result Badge: exactly 170px
              SizedBox(
                width: 170,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: !isOpen && diff != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: diff == 0
                                ? AppColors.success.withValues(alpha: 0.1)
                                : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                diff == 0 ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.warningCircle,
                                size: 12,
                                color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                diff == 0
                                    ? 'Точно (0 с)'
                                    : (diff < 0 ? 'Недостача: ${diff.toCurrency(context)}' : 'Излишек: +${diff.toCurrency(context)}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Активна',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 8),

              // Right Action Caret: 16px (8 + 16 = 24px)
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
