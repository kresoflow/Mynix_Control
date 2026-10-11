// ==============================================================================
// МОДУЛЬ: Настройки / Форма создания и редактирования сотрудника
// ДОМЕН: lib/features/settings/view/widgets/user_form_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/app_dialog.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/dirty_pop_scope.dart';
import 'package:kreso_frontend/core/utils/role_formatter.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:kreso_frontend/features/settings/models/user_model.dart';
import 'package:kreso_frontend/features/settings/bloc/user_bloc.dart';

// ── Диалог управления сотрудником ────────────────────────────────────────────

class UserFormDialog extends StatefulWidget {
  final bool isDark;
  final List<Role> roles;
  final StaffUser? userToEdit;
  final String? currentUserRole;

  const UserFormDialog({
    super.key,
    required this.isDark,
    required this.roles,
    this.userToEdit,
    this.currentUserRole,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isDark,
    required List<Role> roles,
    StaffUser? userToEdit,
  }) {
    final userBloc = context.read<UserBloc>();
    final authState = context.read<AuthBloc>().state;
    final currentRole = authState is AuthAuthenticated ? authState.role : null;

    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: userBloc,
        child: UserFormDialog(
          isDark: isDark,
          roles: roles,
          userToEdit: userToEdit,
          currentUserRole: currentRole,
        ),
      ),
    );
  }

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _pinController;
  late final TextEditingController _passwordController;
  late String _selectedRoleName;

  bool get _isEdit => widget.userToEdit != null;

  bool get _isManager {
    final r = (widget.currentUserRole ?? '').toLowerCase();
    return r.contains('manager') && !r.contains('owner') && !r.contains('superadmin');
  }

  Set<String> get _allowedRoleNames => _isManager
      ? const {'cashier'}
      : const {'owner', 'manager', 'cashier'};

  List<Role> get _filteredRoles => widget.roles
      .where((r) => _allowedRoleNames.contains(r.name.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    final u = widget.userToEdit;
    _usernameController = TextEditingController(text: u?.username ?? '');
    _fullNameController = TextEditingController(text: u?.fullName ?? '');
    _pinController = TextEditingController(text: u?.pinCode ?? '');
    _passwordController = TextEditingController();

    if (_isManager) {
      _selectedRoleName = 'cashier';
    } else {
      final existingRole = (u != null && u.roles.isNotEmpty) ? u.roles.first : null;
      final filtered = _filteredRoles;
      if (existingRole != null && _allowedRoleNames.contains(existingRole.toLowerCase())) {
        _selectedRoleName = existingRole;
      } else if (filtered.isNotEmpty) {
        _selectedRoleName = filtered.first.name;
      } else {
        _selectedRoleName = 'cashier';
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final u = widget.userToEdit;
    if (_fullNameController.text.trim() != (u?.fullName ?? '').trim()) return true;
    if (_usernameController.text.trim() != (u?.username ?? '').trim()) return true;
    if (_pinController.text.trim() != (u?.pinCode ?? '').trim()) return true;
    if (_passwordController.text.isNotEmpty) return true;
    final initRole = (u != null && u.roles.isNotEmpty)
        ? u.roles.first
        : (_filteredRoles.isNotEmpty ? _filteredRoles.first.name : 'cashier');
    if (_selectedRoleName != initRole) return true;
    return false;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final filtered = _filteredRoles;
    final selectedRole = filtered.where((r) => r.name.toLowerCase() == _selectedRoleName.toLowerCase()).firstOrNull ??
        (filtered.isNotEmpty ? filtered.first : null);
    final roleIds = selectedRole != null ? [selectedRole.id] : <int>[];

    if (_isEdit) {
      context.read<UserBloc>().add(
            UpdateUser(
              userId: widget.userToEdit!.id,
              username: _usernameController.text.trim(),
              fullName: _fullNameController.text.trim(),
              pinCode: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
              roleIds: roleIds,
              password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
            ),
          );
    } else {
      context.read<UserBloc>().add(
            CreateUser(
              username: _usernameController.text.trim(),
              fullName: _fullNameController.text.trim(),
              password: _passwordController.text.trim().isEmpty ? '123456' : _passwordController.text.trim(),
              pinCode: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
              roleIds: roleIds,
            ),
          );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRoles;

    return DirtyPopScope(
      isDirty: _isDirty,
      title: _isEdit ? 'Отменить изменения?' : 'Отменить создание?',
      message: _isEdit
          ? 'Несохраненные изменения данных сотрудника будут потеряны. Выйти?'
          : 'Все введенные данные сотрудника будут потеряны. Выйти?',
      confirmLabel: 'Сбросить и выйти',
      child: AppDialog(
        title: _isEdit ? 'Редактировать сотрудника' : 'Новый сотрудник',
        icon: PhosphorIconsRegular.user,
        width: 480,
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'ФИО сотрудника', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Заполните ФИО' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Логин', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Заполните логин' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _isEdit ? 'Новый пароль (оставьте пустым)' : 'Пароль (по умолч. 123456)',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN-код для быстрого входа (4 цифры)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^\d{4}$').hasMatch(v.trim())) {
                    return 'PIN-код должен содержать ровно 4 цифры';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: filtered.any((r) => r.name.toLowerCase() == _selectedRoleName.toLowerCase())
                    ? filtered.firstWhere((r) => r.name.toLowerCase() == _selectedRoleName.toLowerCase()).name
                    : (filtered.isNotEmpty ? filtered.first.name : null),
                decoration: InputDecoration(
                  labelText: 'Роль',
                  border: const OutlineInputBorder(),
                  helperText: _isManager ? 'Управляющий может назначать только кассиров' : null,
                ),
                items: filtered
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.name,
                        child: Row(
                          children: [
                            Icon(RoleFormatter.getRoleIcon(r.name), size: 18, color: RoleFormatter.getRoleColor(r.name)),
                            const SizedBox(width: 8),
                            Text(RoleFormatter.formatName(r.name)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isManager
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedRoleName = val);
                      },
              ),
            ],
          ),
        ),
        actions: [
          AppGhostButton(
            label: 'Отмена',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          AppPrimaryButton(
            label: _isEdit ? 'Сохранить' : 'Создать',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
