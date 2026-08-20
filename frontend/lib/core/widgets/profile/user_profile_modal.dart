import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';

void showUserProfileModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const UserProfileModal(),
  );
}

class UserProfileModal extends StatefulWidget {
  const UserProfileModal({super.key});

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPasswordInput = false;

  String _fullName = 'Сотрудник';
  String _username = 'user';
  String _role = 'Персонал';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await apiClient.dio.get('/auth/me');
      if (mounted) {
        final data = response.data;
        setState(() {
          _fullName = data['full_name'] ?? 'Сотрудник';
          _username = data['username'] ?? 'user';
          final roles = data['roles'] as List? ?? [];
          _role = roles.isNotEmpty ? roles.first.toString() : 'Пользователь';
          _pinController.text = data['pin_code']?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final pin = _pinController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> data = {};
      if (pin.isNotEmpty) data['pin_code'] = pin;
      if (password.isNotEmpty) data['password'] = password;

      await apiClient.dio.put('/auth/me', data: data);
      if (mounted) {
        AppToast.showSuccess(context, 'Профиль обновлен', subtitle: 'Новый PIN-код сохранен');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.showError(context, 'Ошибка сохранения', subtitle: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Dialog(
        child: SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MynixDialog(
      title: 'Мой профиль',
      icon: PhosphorIconsRegular.userCircle,
      width: 440,
      actions: [
        AppButton.secondary(
          label: 'Закрыть',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: _isSaving ? 'Сохранение...' : 'Сохранить',
          onPressed: _isSaving ? null : _saveProfile,
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. User Info Header ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                  child: Text(
                    _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('@$_username', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _role,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── 2. Security Section: PIN & Password ──────────────────────
          Text('Безопасность и PIN-код', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(height: 8),

          TextField(
            controller: _pinController,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Личный PIN-код (4-6 цифр)',
              hintText: 'Например, 2222',
              counterText: '',
              prefixIcon: const Icon(PhosphorIconsRegular.lockKey, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),

          if (!_showPasswordInput)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showPasswordInput = true),
                icon: const Icon(PhosphorIconsRegular.key, size: 16),
                label: const Text('Сменить пароль входа', style: TextStyle(fontSize: 12)),
              ),
            )
          else
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                hintText: 'Минимум 6 символов',
                prefixIcon: const Icon(PhosphorIconsRegular.key, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          const SizedBox(height: 14),

          // ── 3. Fast Switch User ──────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LoggedOut());
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(PhosphorIconsRegular.signOut, size: 18),
            label: const Text('Сменить пользователя / Выйти'),
          ),
        ],
      ),
    );
  }
}
