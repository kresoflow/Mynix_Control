import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';

void showCashboxModal(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (ctx) => MynixDialog(
      title: 'Состояние кассы',
      icon: PhosphorIconsRegular.vault,
      width: 440,
      content: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state is ShiftOpen) {
            final shift = state.shiftDetails;
            final expectedCash = shift['current_cash_expected'] ?? shift['opening_cash'];
            
            String openedAtStr = '-';
            if (shift['opened_at'] != null) {
              final parsed = DateTime.tryParse(shift['opened_at'].toString());
              if (parsed != null) {
                openedAtStr = DateFormat('dd.MM.yyyy, HH:mm').format(parsed.toLocal());
              } else {
                openedAtStr = shift['opened_at'].toString();
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoRow('Статус смены', 'ОТКРЫТА', isDark, valueColor: AppColors.success),
                const SizedBox(height: 10),
                _buildInfoRow('Смена открыта', openedAtStr, isDark),
                const SizedBox(height: 10),
                _buildInfoRow('Сумма размена', (shift['opening_cash'] as num).toCurrency(context), isDark),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ожидается в кассе:',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        (expectedCash as num).toCurrency(context),
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Кассовая смена закрыта.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
      actions: [
        AppPrimaryButton(
          label: 'Закрыть',
          height: 42,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value, bool isDark, {Color? valueColor}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
      ),
      Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: valueColor ?? (isDark ? AppColors.darkText : AppColors.lightText),
        ),
      ),
    ],
  );
}
