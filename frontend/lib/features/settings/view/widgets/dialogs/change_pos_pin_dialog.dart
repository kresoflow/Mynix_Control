// ==============================================================================
// МОДУЛЬ: Настройки / Диалог смены мастер-PIN кассы (ChangePosPinDialog)
// ДОМЕН: lib/features/settings/view/widgets/dialogs/change_pos_pin_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

// ─── 1. Диалог обновления мастер-PIN кассы ───────────────────────────────────

/// [UI-KIT] [БЕЗОПАСНОСТЬ] Модальное окно установки и смены мастер-PIN кода кассы.
/// Защищает кассу от раскрытия конфиденциальных сумм посторонними.
class ChangePosPinDialog extends StatefulWidget {
  final bool isDark;

  const ChangePosPinDialog({super.key, required this.isDark});

  /// Открывает диалог смены мастер-PIN кода
  static Future<bool?> show(BuildContext context, {required bool isDark}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: ChangePosPinDialog(isDark: isDark),
      ),
    );
  }

  @override
  State<ChangePosPinDialog> createState() => _ChangePosPinDialogState();
}

class _ChangePosPinDialogState extends State<ChangePosPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4 || pin.length > 6) {
      setState(() => _errorMessage = 'PIN-код должен содержать от 4 до 6 цифр');
      return;
    }

    if (pin != confirm) {
      setState(() => _errorMessage = 'Введенные PIN-коды не совпадают');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      context.read<SettingsBloc>().add(ChangeMasterPin(pin));
      AppToast.showSuccess(
        context,
        'Мастер-PIN кассы успешно обновлен',
        subtitle: 'Новый PIN сохранен для заведения',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Не удалось сохранить PIN: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogScaffold(
      title: 'Мастер-PIN кассы',
      subtitle: 'Управление защитным PIN-кодом торговой точки',
      icon: PhosphorIconsRegular.lockKey,
      dialogSize: AppDialogSize.sm,
      maxHeight: 400,
      actions: [
        AppButton.secondary(
          label: 'Отмена',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton.primary(
          label: 'Сохранить PIN',
          isLoading: _isSaving,
          onPressed: _validateAndSubmit,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Мастер-PIN позволяет управляющему и владельцу быстро раскрывать финансовые суммы на кассе и подтверждать инкассации.',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Новый мастер-PIN',
              hintText: '4-6 цифр',
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              prefixIcon: const Icon(PhosphorIconsRegular.password, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              onSubmitted: (_) => _validateAndSubmit(),
            ),
            const SizedBox(height: 14),
            AppTextField(
              labelText: 'Подтвердите PIN-код',
              hintText: 'Повторите введенный PIN',
              controller: _confirmController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              prefixIcon: const Icon(PhosphorIconsRegular.checkCircle, size: 18),
              onSubmitted: (_) => _validateAndSubmit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.warningCircle, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
