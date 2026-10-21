// ==============================================================================
// МОДУЛЬ: Касса / Диалог ввода PIN-кода администратора (ShiftPinDialog)
// ДОМЕН: lib/features/pos/view/widgets/shift_hub/shift_pin_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/auth/repository/auth_repository.dart';

// ─── 1. Функция открытия диалога (для обратной совместимости) ─────────────────

/// [БЕЗОПАСНОСТЬ] Запрашивает PIN-код управляющего или мастера заведения
/// для раскрытия конфиденциальных финансовых сумм на кассе.
Future<bool> showShiftPinDialog(BuildContext context) {
  return ShiftPinDialog.show(context);
}

// ─── 2. Модальный компонент с безопасным жизненным циклом контроллера ──────────

/// [UI-KIT] [БЕЗОПАСНОСТЬ] Диалог ввода защитного PIN-кода.
/// Контроллер управляется строго в State.dispose() после полного размонтирования дерева.
class ShiftPinDialog extends StatefulWidget {
  const ShiftPinDialog({super.key});

  /// Открывает диалог с гарантией безопасного закрытия
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ShiftPinDialog(),
    );
    return result ?? false;
  }

  @override
  State<ShiftPinDialog> createState() => _ShiftPinDialogState();
}

class _ShiftPinDialogState extends State<ShiftPinDialog> {
  final _pinController = TextEditingController();
  String? _error;
  bool _isChecking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final authRepo = context.read<AuthRepository>();
      final verification = await authRepo.verifyPin(pin);
      if (!mounted) return;

      if (verification.isValid) {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop(true);
        return;
      }

      setState(() {
        _error = verification.message ?? 'Неверный PIN-код';
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка проверки: $e';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppDialogScaffold(
      title: 'Доступ администратора',
      subtitle: 'Подтверждение PIN-кода для раскрытия сумм',
      icon: PhosphorIconsRegular.lockKey,
      dialogSize: AppDialogSize.sm,
      maxHeight: 330,
      actions: [
        AppButton.secondary(
          label: 'Отмена',
          onPressed: _isChecking
              ? null
              : () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop(false);
                },
        ),
        AppButton.primary(
          label: _isChecking ? 'Проверка...' : 'Подтвердить',
          isLoading: _isChecking,
          onPressed: _isChecking ? null : _submitPin,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Введите PIN-код управляющего/владельца или мастер-PIN кассы:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _pinController,
              obscureText: true,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              labelText: 'PIN-код (4-6 цифр)',
              prefixIcon: const Icon(PhosphorIconsRegular.lock, size: 18),
              errorText: _error,
              onSubmitted: (_) => _isChecking ? null : _submitPin(),
            ),
          ],
        ),
      ),
    );
  }
}
