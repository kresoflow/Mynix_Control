import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';

class ShiftZCloseTab extends StatefulWidget {
  final double expectedCash;
  final VoidCallback onUnlockPin;
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
  void dispose() {
    _cashController.dispose();
    super.dispose();
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

        TextField(
          controller: _cashController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w900, fontSize: 24),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: const Icon(PhosphorIconsRegular.money, size: 22),
            suffixText: CurrencyFormatter.symbol(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Blind count hint toggle
        InkWell(
          onTap: () {
            if (!widget.isPinUnlocked && !_showDiscrepancyHint) {
              widget.onUnlockPin();
            }
            setState(() => _showDiscrepancyHint = !_showDiscrepancyHint);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _showDiscrepancyHint ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                    size: 14,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showDiscrepancyHint ? 'Скрыть подсказку' : 'Показать ожидаемую сумму',
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
                ),
            ],
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: diff == 0 ? AppColors.success : (diff < 0 ? AppColors.danger : AppColors.warning),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  diff == 0 ? '✓ Сходится точно' : (diff < 0 ? 'Недостача:' : 'Излишек:'),
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

        AppButton.danger(
          label: 'Подтвердить и закрыть смену',
          icon: PhosphorIconsRegular.lockKey,
          isFullWidth: true,
          height: 48,
          onPressed: () {
            context.read<ShiftBloc>().add(CloseShiftRequested(_actualCash));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
