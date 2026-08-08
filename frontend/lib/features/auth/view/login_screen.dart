import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:dio/dio.dart';
import 'package:mynix_frontend/features/superadmin/domain/superadmin_repository.dart';
import 'package:mynix_frontend/features/superadmin/presentation/bloc/superadmin_bloc.dart';
import 'package:mynix_frontend/features/superadmin/presentation/superadmin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'owner');
  final _passwordController = TextEditingController(text: 'mynix2025');
  bool _obscurePassword = true;
  bool _isPinMode = false;
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
      builder: (ctx) => AlertDialog(
        title: const Text('System Admin Access'),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Admin Token'),
          onChanged: (val) => token = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (token.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (_) => SuperadminBloc(
                        repository: SuperadminRepository(
                          dio: Dio(BaseOptions(
                            baseUrl: 'http://127.0.0.1:8000/api/v1',
                          )),
                        ),
                      ),
                      child: SuperadminScreen(systemToken: token),
                    ),
                  ),
                );
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: colorScheme.error),
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
                    GestureDetector(
                      onLongPress: () {
                        _showSuperadminDialog(context);
                      },
                      child: Text(
                        'Mynix Control',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 32,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
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
                    SizedBox(height: 8),
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
                    SizedBox(height: 16),
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
