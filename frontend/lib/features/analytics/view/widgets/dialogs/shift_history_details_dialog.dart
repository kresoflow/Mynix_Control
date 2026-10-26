// ==============================================================================
// Title: ShiftHistoryDetailsDialog (shift_history_details_dialog.dart)
// Path: frontend/lib/features/analytics/view/widgets/dialogs/shift_history_details_dialog.dart
// Description: Модальное окно детализации Z-отчета завершенной или активной смены.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'shift_report_detail_tiles.dart';

// ─── 1. Диалог детализации кассовой смены (Z-отчет) ──────────────────────────

class ShiftHistoryDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> shift;

  const ShiftHistoryDetailsDialog({super.key, required this.shift});

  static void show(BuildContext context, Map<String, dynamic> shift) {
    showDialog(
      context: context,
      builder: (_) => ShiftHistoryDetailsDialog(shift: shift),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shiftId = shift['id'];
    final isOpen = shift['is_open'] == true;
    final totalRev = (shift['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final cashSales = (shift['cash_sales'] as num?)?.toDouble() ?? 0.0;
    final transferSales = (shift['transfer_sales'] as num?)?.toDouble() ?? 0.0;
    final openingCash = (shift['opening_cash'] as num?)?.toDouble() ?? 0.0;
    final expectedCash = (shift['closing_cash_expected'] as num?)?.toDouble();
    final actualCash = (shift['closing_cash_actual'] as num?)?.toDouble();
    final diff = (shift['discrepancy'] as num?)?.toDouble();
    final ordersCount = shift['orders_count'] ?? 0;
    final itemsCount = shift['items_sold_count'] ?? 0;
    final openedBy = shift['opened_by_name'] ?? 'Не указан';
    final closedBy = shift['closed_by_name'] ?? (isOpen ? 'Смена активна' : 'Не указан');

    String openedStr = '-';
    if (shift['opened_at'] != null) {
      final p = DateTime.tryParse(shift['opened_at'].toString());
      if (p != null) openedStr = DateFormat('dd.MM.yyyy, HH:mm').format(p.toLocal());
    }

    String closedStr = '-';
    if (shift['closed_at'] != null) {
      final p = DateTime.tryParse(shift['closed_at'].toString());
      if (p != null) closedStr = DateFormat('dd.MM.yyyy, HH:mm').format(p.toLocal());
    }

    return AppDialog(
      title: 'Z-Отчет: Смена #$shiftId',
      icon: PhosphorIconsRegular.receipt,
      width: 480,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildShiftInfoTile(
                isDark,
                [
                  buildShiftStatusRow(isOpen, isDark),
                  buildShiftDetailRow('Открыта:', openedStr, isDark),
                  buildShiftDetailRow('Открыл:', openedBy, isDark, icon: PhosphorIconsRegular.user),
                  if (!isOpen) ...[
                    buildShiftDetailRow('Закрыта:', closedStr, isDark),
                    buildShiftDetailRow('Закрыл:', closedBy, isDark, icon: PhosphorIconsRegular.userCheck),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              buildShiftInfoTile(
                isDark,
                [
                  buildShiftDetailRow('Размен на начало:', openingCash.toCurrency(context), isDark),
                  buildShiftDetailRow('Выручка (Наличные):', cashSales.toCurrency(context), isDark, icon: PhosphorIconsRegular.money),
                  buildShiftDetailRow('Выручка (Переводы):', transferSales.toCurrency(context), isDark, icon: PhosphorIconsRegular.creditCard),
                  const Divider(height: 12),
                  buildShiftDetailRow(
                    'ИТОГО ВЫРУЧКА:',
                    totalRev.toCurrency(context),
                    isDark,
                    isBold: true,
                    color: AppColors.brandPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              buildShiftInfoTile(
                isDark,
                [
                  buildShiftDetailRow('Всего чеков:', '$ordersCount шт.', isDark),
                  buildShiftDetailRow('Продано позиций:', '$itemsCount шт.', isDark, isBold: true),
                  buildShiftDetailRow(
                    'Средний чек:',
                    ordersCount > 0 ? (totalRev / ordersCount).toCurrency(context) : '0 с',
                    isDark,
                  ),
                ],
              ),
              if (!isOpen && expectedCash != null) ...[
                const SizedBox(height: 10),
                buildShiftInfoTile(
                  isDark,
                  [
                    buildShiftDetailRow('Ожидалось в кассе:', expectedCash.toCurrency(context), isDark),
                    if (actualCash != null)
                      buildShiftDetailRow('Фактически в кассе:', actualCash.toCurrency(context), isDark),
                    if (diff != null) ...[
                      const Divider(height: 12),
                      buildShiftDiscrepancyRow(diff, isDark, context),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppButton.primary(
          label: 'Закрыть',
          height: 40,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
