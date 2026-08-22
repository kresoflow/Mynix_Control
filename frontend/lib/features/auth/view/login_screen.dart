import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_logo_base64.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/superadmin/domain/superadmin_repository.dart';
import 'package:mynix_frontend/features/superadmin/presentation/bloc/superadmin_bloc.dart';
import 'package:mynix_frontend/features/superadmin/presentation/superadmin_screen.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final bool _isPinMode = false;
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }


  void _login() {
    if (_isPinMode) {
      final pin = _pinController.text;
      if (pin.isNotEmpty) {
        context.read<AuthBloc>().add(LoginByPinRequested(pin));
      }
    } else {
      final username = _usernameController.text;
      final password = _passwordController.text;
      if (username.isNotEmpty && password.isNotEmpty) {
        context.read<AuthBloc>().add(LoginRequested(username, password));
      }
    }
  }

  void _showSuperadminDialog(BuildContext context) {
    String token = '';
    showDialog(
      context: context,
      builder: (ctx) => MynixDialog(
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
              labelText: 'Мастер-токен',
              hintText: 'токен доступа...',
              obscureText: true,
              prefixIcon: const Icon(PhosphorIconsRegular.key, size: 18),
              onChanged: (val) => token = val.trim(),
            ),
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
              Navigator.pop(ctx);
              if (token.isNotEmpty) {
                final apiClient = context.read<ApiClient>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (_) => SuperadminBloc(
                        repository: SuperadminRepository(
                          dio: apiClient.dio,
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppToast.showError(
              context,
              'Ошибка авторизации',
              subtitle: state.message,
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.memory(
                      AppLogoData.bytes,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onLongPress: () {
                        _showSuperadminDialog(context);
                      },
                      child: Text(
                        'Kreso Flow',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добро пожаловать',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.darkSubtext,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Имя пользователя',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(PhosphorIcons.user()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(PhosphorIcons.lock()),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Забыли пароль?',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: state is AuthLoading ? null : _login,
                          child: state is AuthLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('ВОЙТИ', style: AppTextStyles.buttonLarge),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Нет аккаунта?', style: AppTextStyles.body),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Зарегистрироваться',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.brandPrimary),
                          ),
                        ),
                      ],
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
