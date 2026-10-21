import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_event.dart';
import 'package:kreso_frontend/features/pos/models/cash_operation.dart';
import 'package:kreso_frontend/features/pos/view/widgets/cash_operations/cash_operation_dialog.dart';
import 'package:kreso_frontend/features/pos/view/widgets/pos_shift_hub_modal.dart';

class ShiftXReportTab extends StatelessWidget {
  final Map<String, dynamic>? report;
  final bool isLoading;
  final String? error;
  final bool hideAmounts;
  final double expectedCash;
  final VoidCallback onUnlockPin;
  final VoidCallback? onRefresh;

  const ShiftXReportTab({
    super.key,
    required this.report,
    required this.isLoading,
    required this.error,
    required this.hideAmounts,
    required this.expectedCash,
    required this.onUnlockPin,
    this.onRefresh,
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
      final isAuth = error!.contains('Сессия истекла') || error!.contains('authenticated');
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsRegular.warningCircle, size: 28, color: AppColors.danger),
            const SizedBox(height: 8),
            Text(error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (isAuth)
              AppPrimaryButton(
                label: 'Войти заново',
                icon: PhosphorIconsRegular.signIn,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  context.read<AuthBloc>().add(LoggedOut());
                },
              )
            else if (onRefresh != null)
              AppSecondaryButton(label: 'Повторить попытку', icon: PhosphorIconsRegular.arrowClockwise, onPressed: onRefresh),
          ],
        ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Единая карточка финансовых показателей ─────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              _buildIconStatRow(context, PhosphorIconsRegular.wallet, 'Кассовый остаток на начало', openingCash, isDark),
              const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Divider(height: 1)),
              _buildIconStatRow(context, PhosphorIconsRegular.money, 'Выручка (Наличные)', cashSales, isDark),
              const SizedBox(height: 4),
              _buildIconStatRow(context, PhosphorIconsRegular.qrCode, 'Выручка (Переводы)', transferSales, isDark),
              const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Divider(height: 1)),
              _buildIconStatRow(context, PhosphorIconsRegular.chartLineUp, 'ИТОГО ВЫРУЧКА', totalRevenue, isDark, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── 2. Чеки и средний чек ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Всего чеков: $ordersCount шт.', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              Text('Средний чек: ${hideAmounts ? '••••' : avgCheck.toCurrency(context)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── 3. Ожидается в кассе баннер ────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsRegular.vault, size: 16, color: AppColors.brandPrimary),
                  const SizedBox(width: 8),
                  Text('Ожидается в кассе (Нал):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkText : AppColors.lightText)),
                ],
              ),
              Text(
                hideAmounts ? '•••• с' : expectedCash.toCurrency(context),
                style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── 4. Кнопки кассовых операций ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: 'Внесение',
                icon: PhosphorIconsRegular.arrowDownLeft,
                height: 36,
                onPressed: () => _handleCashOp(context, CashOpType.deposit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton.secondary(
                label: 'Инкассация / Расход',
                icon: PhosphorIconsRegular.arrowUpRight,
                height: 36,
                onPressed: () => _handleCashOp(context, CashOpType.withdrawal),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleCashOp(BuildContext context, CashOpType type) async {
    if (type == CashOpType.withdrawal && hideAmounts) {
      onUnlockPin();
      return;
    }
    final rootNav = Navigator.of(context, rootNavigator: true);
    final appContext = rootNav.context;
    rootNav.pop();
    final res = await showCashOperationDialog(appContext, initialType: type);
    if (res == true && onRefresh != null) onRefresh!();
    if (appContext.mounted) showShiftHubModal(appContext);
  }

  Widget _buildIconStatRow(BuildContext context, IconData icon, String label, double value, bool isDark, {bool isBold = false}) {
    final sub = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isBold ? AppColors.brandPrimary : sub),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w800 : FontWeight.w500, color: isBold ? text : sub)),
          ],
        ),
        Text(
          hideAmounts ? '••••' : value.toCurrency(context),
          style: TextStyle(fontSize: isBold ? 13 : 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: isBold ? AppColors.brandPrimary : text),
        ),
      ],
    );
  }
}
