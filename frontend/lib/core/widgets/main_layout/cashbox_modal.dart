import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';

void showCashboxModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Состояние кассы'),
      content: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state is ShiftOpen) {
            final shift = state.shiftDetails;
            final expectedCash = shift['current_cash_expected'] ?? shift['opening_cash'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Смена открыта: ${shift['opened_at']}', style: AppTextStyles.body),
                const SizedBox(height: 8),
                Text('Сумма размена: ${shift['opening_cash']} с', style: AppTextStyles.body),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Ожидаемая сумма: $expectedCash с',
                  style: AppTextStyles.h2,
                ),
              ],
            );
          }
          return Text('Смена закрыта.', style: AppTextStyles.body);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Закрыть'),
        ),
      ],
    ),
  );
}
