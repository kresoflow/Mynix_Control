import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

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
    final closedBy = shift['closed_by_name'] ?? (isOpen ? 'Смена еще открыта' : 'Не указан');

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

    return MynixDialog(
      title: 'Z-Отчет: Смена #$shiftId',
      icon: PhosphorIconsRegular.receipt,
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoTile(
            isDark,
            [
              _buildRow('Статус:', isOpen ? '🟢 Активна' : '⚪ Закрыта', isDark, isHighlight: true),
              _buildRow('Открыта:', openedStr, isDark),
              _buildRow('Открыл:', openedBy, isDark),
              if (!isOpen) ...[
                _buildRow('Закрыта:', closedStr, isDark),
                _buildRow('Закрыл:', closedBy, isDark),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            isDark,
            [
              _buildRow('Размен на начало:', openingCash.toCurrency(context), isDark),
              _buildRow('Выручка (Наличные):', cashSales.toCurrency(context), isDark),
              _buildRow('Выручка (Переводы):', transferSales.toCurrency(context), isDark),
              const Divider(height: 14),
              _buildRow('ИТОГО ВЫРУЧКА:', totalRev.toCurrency(context), isDark, isBold: true, color: AppColors.brandPrimary),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            isDark,
            [
              _buildRow('Всего чеков:', '$ordersCount шт.', isDark),
              _buildRow('Продано позиций:', '$itemsCount шт.', isDark, isBold: true),
              _buildRow(
                'Средний чек:',
                ordersCount > 0 ? (totalRev / ordersCount).toCurrency(context) : '0 с',
                isDark,
              ),
            ],
          ),
          if (!isOpen && expectedCash != null) ...[
            const SizedBox(height: 12),
            _buildInfoTile(
              isDark,
              [
                _buildRow('Ожидалось в кассе:', expectedCash.toCurrency(context), isDark),
                if (actualCash != null)
                  _buildRow('Фактически в кассе:', actualCash.toCurrency(context), isDark),
                if (diff != null) ...[
                  const Divider(height: 14),
                  _buildRow(
                    'Результат кассы:',
                    diff == 0
                        ? '✓ Точно (0 с)'
                        : (diff < 0 ? 'Недостача: ${diff.toCurrency(context)}' : 'Излишек: +${diff.toCurrency(context)}'),
                    isDark,
                    isBold: true,
                    color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                  ),
                ],
              ],
            ),
          ],
        ],
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

  Widget _buildInfoTile(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark, {bool isBold = false, bool isHighlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color ?? (isDark ? AppColors.darkText : AppColors.lightText),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
