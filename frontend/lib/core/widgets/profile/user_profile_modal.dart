import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/features/auth/repository/auth_repository.dart';
import 'package:mynix_frontend/core/utils/role_formatter.dart';
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
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPasswordInput = false;

  String _username = 'user';
  String _role = 'staff';
  String _tenantName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    try {
      final authRepo = context.read<AuthRepository>();
      final data = await authRepo.getMe();
      if (mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _username = data['username'] ?? 'user';
          final roles = data['roles'] as List? ?? [];
          _role = roles.isNotEmpty ? roles.first.toString() : 'staff';
          _tenantName = data['tenant_name']?.toString() ?? '';
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
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> data = {};
      if (name.isNotEmpty) data['full_name'] = name;
      if (pin.isNotEmpty) data['pin_code'] = pin;
      if (password.isNotEmpty) data['password'] = password;

      final authRepo = context.read<AuthRepository>();
      await authRepo.updateProfile(data);
      if (mounted) {
        context.read<AuthBloc>().add(RefreshProfile());
        AppToast.showSuccess(context, 'Профиль сохранен', subtitle: 'Данные успешно обновлены');
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

    final initial = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U';

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
          // ── 1. Read-Only System Identity Card ───────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$_username',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (_tenantName.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.storefront, size: 12, color: AppColors.darkSubtext),
                            const SizedBox(width: 4),
                            Text(
                              _tenantName,
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Системный аккаунт',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        ),
                    ],
                  ),
                ),
                RoleFormatter.buildBadge(_role),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Editable Full Name ───────────────────────────────────
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'ФИО сотрудника',
              hintText: 'Например, Иванов Сергей',
              prefixIcon: const Icon(PhosphorIconsRegular.user, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // ── 3. Security Section: PIN & Password ──────────────────────
          Text(
            'Безопасность и PIN-код',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _pinController,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Личный PIN-код (4-6 цифр)',
              hintText: 'Например, 1234',
              counterText: '',
              prefixIcon: const Icon(PhosphorIconsRegular.lockKey, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

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
        ],
      ),
    );
  }
}
