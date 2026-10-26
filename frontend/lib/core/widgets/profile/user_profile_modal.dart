// ==============================================================================
// МОДУЛЬ: Профиль / Модальное окно профиля пользователя (User Profile Modal)
// ДОМЕН: lib/core/widgets/profile/user_profile_modal.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/core/utils/role_formatter.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_event.dart';
import 'package:kreso_frontend/features/auth/repository/auth_repository.dart';

void showUserProfileModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const UserProfileModal(),
  );
}

/// [UI-KIT] Модальное окно просмотра и редактирования профиля (AppCardDialog)
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
      return AppCardDialog(
        title: 'Мой профиль',
        subtitle: 'Управление личными данными и безопасностью',
        icon: PhosphorIconsRegular.userCircle,
        width: 440,
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        body: const SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final initial = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U';

    return AppCardDialog(
      title: 'Мой профиль',
      subtitle: 'Управление личными данными и безопасностью',
      icon: PhosphorIconsRegular.userCircle,
      width: 440,
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          label: _isSaving ? 'Сохранение...' : 'Сохранить',
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveProfile,
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Read-Only System Identity Card ───────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: AppRadii.buttonRadius,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$_username',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      if (_tenantName.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.storefront, size: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
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
          AppTextField(
            controller: _nameController,
            labelText: 'ФИО сотрудника',
            hintText: 'Например, Иванов Сергей',
            prefixIcon: const Icon(PhosphorIconsRegular.user, size: 18),
          ),
          const SizedBox(height: 14),

          // ── 3. Security Section: PIN & Password ──────────────────────
          Text(
            'Безопасность и PIN-код',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          const SizedBox(height: 8),

          AppTextField(
            controller: _pinController,
            labelText: 'Личный PIN-код (4-6 цифр)',
            hintText: 'Например, 1234',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(PhosphorIconsRegular.lockKey, size: 18),
          ),
          const SizedBox(height: 8),

          if (!_showPasswordInput)
            Align(
              alignment: Alignment.centerLeft,
              child: AppGhostButton(
                label: 'Сменить пароль входа',
                icon: PhosphorIconsRegular.key,
                size: AppButtonSize.sm,
                onPressed: () => setState(() => _showPasswordInput = true),
              ),
            )
          else
            AppTextField(
              controller: _passwordController,
              labelText: 'Новый пароль',
              hintText: 'Минимум 6 символов',
              obscureText: true,
              prefixIcon: const Icon(PhosphorIconsRegular.key, size: 18),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
