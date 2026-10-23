import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_logo_base64.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_event.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/features/superadmin/repository/superadmin_repository.dart';
import 'package:kreso_frontend/features/superadmin/bloc/superadmin_bloc.dart';
import 'package:kreso_frontend/features/superadmin/view/superadmin_screen.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_text_field.dart';

import 'widgets/pin_keypad.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPinMode = true; // Default to fast PIN login for staff/waiters
  String _pinCode = '';

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

  void _showSuperadminDialog(BuildContext context) async {
    final defaultToken = kDebugMode ? 'super_secret_kreso_token_2026' : '';
    final controller = TextEditingController(text: defaultToken);
    try {
      await showDialog(
        context: context,
        builder: (ctx) => AppDialog(
          title: 'Супер-администратор',
          icon: PhosphorIconsRegular.shieldCheck,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Введите мастер-токен для доступа к платформе:',
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: controller,
                labelText: 'Мастер-токен',
                hintText: 'токен доступа...',
                obscureText: true,
                prefixIcon: const Icon(PhosphorIconsRegular.key, size: 18),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Dev токен: super_secret_kreso_token_2026',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandPrimary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            AppGhostButton(
              label: 'Отмена',
              onPressed: () => Navigator.pop(ctx),
            ),
            AppPrimaryButton(
              label: 'Войти',
              icon: PhosphorIconsRegular.signIn,
              onPressed: () {
                final token = controller.text.trim();
                Navigator.pop(ctx);
                if (token.isNotEmpty) {
                  final apiClient = context.read<ApiClient>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => SuperadminBloc(
                          repository: SuperadminRepository(dio: apiClient.dio),
                        ),
                        child: SuperadminScreen(systemToken: token),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
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
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.memory(AppLogoData.bytes, height: 48, fit: BoxFit.contain),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onLongPress: () => _showSuperadminDialog(context),
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
                      // Mode Selector Switch
                      _buildModeSelector(isDark),
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
                        _buildPasswordForm(isDark),
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

  Widget _buildModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadii.radiusXl,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'PIN-код',
              icon: PhosphorIconsRegular.hash,
              isSelected: _isPinMode,
              onTap: () => setState(() {
                _isPinMode = true;
                _pinCode = '';
              }),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Логин и пароль',
              icon: PhosphorIconsRegular.user,
              isSelected: !_isPinMode,
              onTap: () => setState(() => _isPinMode = false),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.inputRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : AppColors.transparent,
          borderRadius: AppRadii.inputRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.pureWhite : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.pureWhite : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Имя пользователя',
            border: OutlineInputBorder(borderRadius: AppRadii.buttonRadius),
            prefixIcon: Icon(PhosphorIconsRegular.user, size: 18),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Пароль',
            border: const OutlineInputBorder(borderRadius: AppRadii.buttonRadius),
            prefixIcon: const Icon(PhosphorIconsRegular.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => _loginByPassword(),
        ),
        const SizedBox(height: 20),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return AppPrimaryButton(
              label: 'ВОЙТИ',
              height: 50,
              isFullWidth: true,
              isLoading: state is AuthLoading,
              onPressed: state is AuthLoading ? null : _loginByPassword,
            );
          },
        ),
      ],
    );
  }
}
