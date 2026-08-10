import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';

class SettingsDialogs {
  static void showCloseShiftDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Закрытие смены'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите фактическую сумму наличных в кассе (Z-отчет):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Сумма (с)',
                prefixIcon: Icon(PhosphorIconsRegular.money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              context.read<ShiftBloc>().add(CloseShiftRequested(amount));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            child: const Text('ЗАКРЫТЬ'),
          ),
        ],
      ),
    );
  }
}
