import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';

class ShiftZCloseTab extends StatefulWidget {
  final double expectedCash;
  final Future<bool> Function() onUnlockPin;
  final bool isPinUnlocked;

  const ShiftZCloseTab({
    super.key,
    required this.expectedCash,
    required this.onUnlockPin,
    required this.isPinUnlocked,
  });

  @override
  State<ShiftZCloseTab> createState() => _ShiftZCloseTabState();
}

class _ShiftZCloseTabState extends State<ShiftZCloseTab> {
  final _cashController = TextEditingController();
  double _actualCash = 0;
  bool _showDiscrepancyHint = false;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() {
      final val = double.tryParse(_cashController.text.replaceAll(',', '.')) ?? 0;
      setState(() => _actualCash = val);
    });
  }

  @override
  void didUpdateWidget(covariant ShiftZCloseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPinUnlocked && !widget.isPinUnlocked) {
      setState(() => _showDiscrepancyHint = false);
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _toggleDiscrepancyHint() async {
    if (!widget.isPinUnlocked) {
      final unlocked = await widget.onUnlockPin();
      if (!unlocked || !mounted) return;
      setState(() => _showDiscrepancyHint = true);
    } else {
      setState(() => _showDiscrepancyHint = !_showDiscrepancyHint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diff = _actualCash - widget.expectedCash;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Пересчитайте наличные в кассовом ящике:',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: _cashController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hintText: '0.00',
          prefixIcon: const Icon(PhosphorIconsRegular.money, size: 20),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              widthFactor: 1,
              child: Text(
                CurrencyFormatter.symbol(context),
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Blind count hint toggle
        InkWell(
          onTap: _toggleDiscrepancyHint,
          borderRadius: AppRadii.radiusXs,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _showDiscrepancyHint
                          ? PhosphorIconsRegular.eye
                          : (widget.isPinUnlocked ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.lockKey),
                      size: 14,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showDiscrepancyHint
                          ? 'Скрыть подсказку'
                          : (widget.isPinUnlocked ? 'Показать ожидаемую сумму' : 'Показать ожидаемую сумму (PIN)'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
                if (_showDiscrepancyHint)
                  Text(
                    widget.expectedCash.toCurrency(context),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                  )
                else if (!widget.isPinUnlocked)
                  Text(
                    '••••',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_showDiscrepancyHint) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: diff == 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
              borderRadius: AppRadii.radiusMd,
              border: Border.all(
                color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  diff == 0 ? 'Сходится точно' : (diff < 0 ? 'Недостача:' : 'Излишек:'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                  ),
                ),
                Text(
                  diff.abs().toCurrency(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: AppDangerButton(
            label: 'Подтвердить и закрыть смену',
            icon: PhosphorIconsRegular.lockKey,
            onPressed: () => _handleCloseShift(context, diff),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCloseShift(BuildContext context, double diff) async {
    final symbol = CurrencyFormatter.symbol(context);

    // Guard 1: Zero cash entered while positive expected cash
    if (_actualCash <= 0 && widget.expectedCash > 0) {
      final message = widget.isPinUnlocked
          ? 'Вы указали 0.00 $symbol наличных, хотя в кассе ожидается ${widget.expectedCash.toCurrency(context)}.\n\nЭто зафиксирует полную недостачу в кассе.\nВы действительно пересчитали ящик и там 0.00?'
          : 'Вы указали 0.00 $symbol наличных при наличии операций в кассе.\n\nЭто зафиксирует полную недостачу в кассе.\nВы действительно пересчитали ящик и там 0.00?';
      final confirmed = await AppConfirmDialog.show(
        context: context,
        title: 'Касса пуста?',
        message: message,
        confirmLabel: 'Да, в кассе пусто',
        confirmIcon: PhosphorIconsRegular.lockKey,
        cancelLabel: 'Пересчитать',
        isDanger: true,
        icon: PhosphorIconsRegular.warningOctagon,
      );
      if (confirmed != true || !mounted) return;
    }
    // Guard 2: Discrepancy warning (shortage or surplus)
    else if (diff.abs() > 0.01) {
      final diffText = diff < 0
          ? 'недостача ${diff.abs().toCurrency(context)}'
          : 'излишек ${diff.toCurrency(context)}';
      final message = widget.isPinUnlocked
          ? 'Фактический остаток не сходится с кассой:\n$diffText.\n\nЗафиксировать закрытие смены с данным расхождением?'
          : 'Фактический остаток не сходится с расчетными данными кассы.\n\nЗафиксировать закрытие смены с фактическим расхождением?';
      final confirmed = await AppConfirmDialog.show(
        context: context,
        title: 'Подтвердите расхождение',
        message: message,
        confirmLabel: 'Закрыть с расхождением',
        confirmIcon: PhosphorIconsRegular.check,
        cancelLabel: 'Перепроверить',
        isDanger: diff < 0,
        icon: PhosphorIconsRegular.warning,
      );
      if (confirmed != true || !mounted) return;
    }

    if (!context.mounted) return;
    context.read<ShiftBloc>().add(CloseShiftRequested(_actualCash));
    Navigator.of(context).pop();
  }
}
