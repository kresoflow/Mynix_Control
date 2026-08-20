import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/auth/repository/auth_repository.dart';
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

          final isValid = await authRepo.verifyPin(pin);
          if (isValid) {
            if (ctx.mounted) Navigator.of(ctx).pop(true);
            return;
          }

          if (ctx.mounted) {
            setState(() {
              error = 'Неверный PIN-код';
              isChecking = false;
            });
          }
        }

        return MynixDialog(
          title: 'Доступ администратора',
          icon: PhosphorIconsRegular.lockKey,
          width: 360,
          actions: [
            AppButton.secondary(
              label: 'Отмена',
              onPressed: () {
                if (ctx.mounted) Navigator.of(ctx).pop(false);
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
              TextField(
                controller: pinController,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'PIN-код (4-6 цифр)',
                  counterText: '',
                  prefixIcon: const Icon(PhosphorIconsRegular.lock, size: 18),
                  errorText: error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
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
