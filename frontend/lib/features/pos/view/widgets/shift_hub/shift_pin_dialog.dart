// ==============================================================================
// 1. Title: Shift PIN Dialog (Protected Financials Access)
// 2. Role: Secure prompt for manager / owner PIN code with brute-force guards.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_text_field.dart';
import 'package:kreso_frontend/features/auth/repository/auth_repository.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<bool> showShiftPinDialog(BuildContext context) async {
  final pinController = TextEditingController();
  final authRepo = context.read<AuthRepository>();
  String? error;
  bool isChecking = false;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Future<void> submitPin() async {
          final pin = pinController.text.trim();
          if (pin.isEmpty) return;

          setState(() {
            isChecking = true;
            error = null;
          });

          final verification = await authRepo.verifyPin(pin);
          if (!ctx.mounted) return;

          if (verification.isValid) {
            final nav = Navigator.of(ctx);
            if (nav.canPop()) nav.pop(true);
            return;
          }

          setState(() {
            error = verification.message ?? 'Неверный PIN-код';
            isChecking = false;
          });
        }

        return AppDialog(
          title: 'Доступ администратора',
          icon: PhosphorIconsRegular.lockKey,
          width: 360,
          actions: [
            AppButton.secondary(
              label: 'Отмена',
              onPressed: () {
                if (ctx.mounted) {
                  final nav = Navigator.of(ctx);
                  if (nav.canPop()) nav.pop(false);
                }
              },
            ),
            AppButton.primary(
              label: isChecking ? 'Проверка...' : 'Подтвердить',
              onPressed: isChecking ? null : submitPin,
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Введите PIN-код управляющего/владельца для доступа к суммам:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: pinController,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                labelText: 'PIN-код (4-6 цифр)',
                prefixIcon: const Icon(PhosphorIconsRegular.lock, size: 18),
                errorText: error,
                onSubmitted: (_) => isChecking ? null : submitPin(),
              ),
            ],
          ),
        );
      },
    ),
  );

  pinController.dispose();
  return result ?? false;
}
