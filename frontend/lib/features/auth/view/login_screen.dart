import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_logo_base64.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_event.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';

import 'widgets/login_mode_selector.dart';
import 'widgets/login_password_form.dart';
import 'widgets/pin_keypad.dart';
import 'widgets/superadmin_access_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPinMode = false;
  String _pinCode = '';

  @override
  void initState() {
    super.initState();
    _checkInitialMode();
  }

  Future<void> _checkInitialMode() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTenantId = prefs.getInt('last_tenant_id') ?? 0;
    if (mounted && lastTenantId > 0) {
      setState(() => _isPinMode = true);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginByPassword() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(LoginRequested(username, password));
    }
  }

  void _loginByPin() {
    if (_pinCode.length == 4) {
      context.read<AuthBloc>().add(LoginByPinRequested(_pinCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            setState(() => _pinCode = '');
            AppToast.showError(
              context,
              'Ошибка авторизации',
              subtitle: state.message,
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 8,
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.memory(AppLogoData.bytes, height: 48, fit: BoxFit.contain),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onLongPress: () => SuperadminAccessDialog.show(context),
                        child: Text(
                          'Kreso Flow',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 24,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPinMode ? 'Быстрый вход для персонала' : 'Вход для администратора',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LoginModeSelector(
                        isPinMode: _isPinMode,
                        isDark: isDark,
                        onModeChanged: (pinMode) => setState(() {
                          _isPinMode = pinMode;
                          if (pinMode) _pinCode = '';
                        }),
                      ),
                      const SizedBox(height: 24),
                      if (_isPinMode)
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthLoading) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(),
                              );
                            }
                            return PinKeypad(
                              pin: _pinCode,
                              isDark: isDark,
                              onPinChanged: (val) => setState(() => _pinCode = val),
                              onComplete: _loginByPin,
                            );
                          },
                        )
                      else
                        LoginPasswordForm(
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          onSubmit: _loginByPassword,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
