// ==============================================================================
// МОДУЛЬ: Настройки / Системные диалоги (Settings Dialogs)
// ДОМЕН: lib/features/settings/view/widgets/settings_dialogs.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';

/// Диалоги для управления сменами и системными настройками
class SettingsDialogs {
  static void showCloseShiftDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        icon: PhosphorIconsRegular.lockKey,
        title: 'Закрытие смены',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          AppDangerButton(
            label: 'ЗАКРЫТЬ',
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              context.read<ShiftBloc>().add(CloseShiftRequested(amount));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
