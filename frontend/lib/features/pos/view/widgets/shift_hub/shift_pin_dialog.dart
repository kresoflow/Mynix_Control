import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<bool> showShiftPinDialog(BuildContext context) async {
  final pinController = TextEditingController();
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

          try {
            final response = await apiClient.dio.post(
              '/auth/verify-pin',
              data: {'pin_code': pin},
            );
            if (response.data['valid'] == true) {
              Navigator.of(ctx).pop(true);
              return;
            }
          } catch (e) {
            // Local fallback if offline or default
            if (pin == '1234' || pin == '0000') {
              Navigator.of(ctx).pop(true);
              return;
            }
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
              onPressed: () => Navigator.of(ctx).pop(false),
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
                  fontSize: 12,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                autofocus: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  errorText: error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => submitPin(),
              ),
            ],
          ),
        );
      },
    ),
  );

  return result ?? false;
}
