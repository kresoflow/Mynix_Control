import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

class ShiftXReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final bool isLoading;
  final String? error;
  final bool hideAmounts;
  final double expectedCash;
  final VoidCallback onUnlockPin;

  const ShiftXReportTab({
    super.key,
    required this.report,
    required this.isLoading,
    required this.error,
    required this.hideAmounts,
    required this.expectedCash,
    required this.onUnlockPin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text('Ошибка загрузки: $error', style: const TextStyle(color: AppColors.danger)),
      );
    }

    final openingCash = (num.tryParse(report?['opening_cash']?.toString() ?? '0') ?? 0).toDouble();
    final cashSales = (num.tryParse(report?['cash_sales']?.toString() ?? '0') ?? 0).toDouble();
    final transferSales = (num.tryParse(report?['transfer_sales']?.toString() ?? '0') ?? 0).toDouble();
    final totalRevenue = (num.tryParse(report?['total_revenue']?.toString() ?? '0') ?? 0).toDouble();
    final ordersCount = report?['orders_count'] ?? 0;
    final avgCheck = (num.tryParse(report?['average_check']?.toString() ?? '0') ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hideAmounts)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.shieldCheck, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 8),
                    const Text('Режим скрытия данных', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                InkWell(
                  onTap: onUnlockPin,
                  child: Text('Разблокировать (PIN)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                ),
              ],
            ),
          ),

        _buildStatRow(context, 'Кассовый остаток на начало', openingCash, isDark),
        const SizedBox(height: 10),

        // Revenue Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              _buildIconStatRow(context, PhosphorIconsRegular.money, 'Выручка (Наличные)', cashSales, isDark),
              const SizedBox(height: 6),
              _buildIconStatRow(context, PhosphorIconsRegular.qrCode, 'Выручка (Переводы)', transferSales, isDark),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1),
              ),
              _buildIconStatRow(context, PhosphorIconsRegular.chartLineUp, 'ИТОГО ВЫРУЧКА', totalRevenue, isDark, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Orders & Avg Check
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Всего чеков: $ordersCount шт.', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            Text('Средний чек: ${hideAmounts ? '••••' : avgCheck.toCurrency(context)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
          ],
        ),
        const SizedBox(height: 14),

        // Expected Cash Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ожидается в кассе (Нал):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text(
                hideAmounts ? '•••• с' : expectedCash.toCurrency(context),
                style: AppTextStyles.h2.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        AppButton.secondary(
          label: 'Закрыть окно',
          isFullWidth: true,
          height: 42,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, double value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        Text(hideAmounts ? '••••' : value.toCurrency(context), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkText : AppColors.lightText)),
      ],
    );
  }

  Widget _buildIconStatRow(BuildContext context, IconData icon, String label, double value, bool isDark, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isBold ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
        Text(
          hideAmounts ? '••••' : value.toCurrency(context),
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: isBold ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
          ),
        ),
      ],
    );
  }
}
