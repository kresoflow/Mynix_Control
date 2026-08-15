import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CloseShiftModal extends StatefulWidget {
  final double expectedCash;

  const CloseShiftModal({super.key, required this.expectedCash});

  @override
  State<CloseShiftModal> createState() => _CloseShiftModalState();
}

class _CloseShiftModalState extends State<CloseShiftModal> {
  final _controller = TextEditingController();
  double _actualCash = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final val = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
      setState(() => _actualCash = val);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diff = _actualCash - widget.expectedCash;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(PhosphorIconsRegular.lockKey, color: AppColors.brandPrimary, size: 26),
                const SizedBox(width: 10),
                Text(
                  'ЗАКРЫТИЕ СМЕНЫ (Z-ОТЧЕТ)',
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ожидается в кассе:', style: AppTextStyles.bodyMedium),
                Text(widget.expectedCash.toCurrency(context), style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Введите фактическую сумму наличных в ящике:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                suffixText: 'сом',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: diff == 0 
                    ? AppColors.success.withValues(alpha: 0.1)
                    : (diff < 0 ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: diff == 0 
                      ? AppColors.success 
                      : (diff < 0 ? AppColors.danger : AppColors.warning),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    diff == 0 
                        ? 'Совпадает точно' 
                        : (diff < 0 ? 'Недостача:' : 'Излишек:'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: diff == 0 
                          ? AppColors.success 
                          : (diff < 0 ? AppColors.danger : AppColors.warning),
                    ),
                  ),
                  Text(
                    diff.abs().toCurrency(context),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: diff == 0 
                          ? AppColors.success 
                          : (diff < 0 ? AppColors.danger : AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ОТМЕНА'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<ShiftBloc>().add(CloseShiftRequested(_actualCash));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ЗАКРЫТЬ СМЕНУ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
