// ==============================================================================
// МОДУЛЬ: Авторизация / Форма входа по логину и паролю
// ДОМЕН: lib/features/auth/view/widgets/login_password_form.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Поля ввода логина и пароля с кнопкой входа:
// 1. Поддержка скрытия/показа пароля.
// 2. Интеграция состояния AuthLoading для предотвращения повторной отправки.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';

class LoginPasswordForm extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const LoginPasswordForm({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  State<LoginPasswordForm> createState() => _LoginPasswordFormState();
}

class _LoginPasswordFormState extends State<LoginPasswordForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.usernameController,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Имя пользователя',
            border: OutlineInputBorder(borderRadius: AppRadii.buttonRadius),
            prefixIcon: Icon(PhosphorIconsRegular.user, size: 18),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Пароль',
            border: const OutlineInputBorder(borderRadius: AppRadii.buttonRadius),
            prefixIcon: const Icon(PhosphorIconsRegular.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => widget.onSubmit(),
        ),
        const SizedBox(height: 20),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return AppPrimaryButton(
              label: 'ВОЙТИ',
              height: 50,
              isFullWidth: true,
              isLoading: state is AuthLoading,
              onPressed: state is AuthLoading ? null : widget.onSubmit,
            );
          },
        ),
      ],
    );
  }
}
