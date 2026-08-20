import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/widgets/mynix_dialog.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:mynix_frontend/features/settings/models/user_model.dart';
import 'package:mynix_frontend/features/settings/bloc/user_bloc.dart';
import 'package:mynix_frontend/core/utils/role_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserFormDialog extends StatefulWidget {
  final bool isDark;
  final List<Role> roles;
  final StaffUser? userToEdit;

  const UserFormDialog({
    super.key,
    required this.isDark,
    required this.roles,
    this.userToEdit,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isDark,
    required List<Role> roles,
    StaffUser? userToEdit,
  }) {
    final userBloc = context.read<UserBloc>();
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: userBloc,
        child: UserFormDialog(isDark: isDark, roles: roles, userToEdit: userToEdit),
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

  @override
  void initState() {
    super.initState();
    final u = widget.userToEdit;
    _usernameController = TextEditingController(text: u?.username ?? '');
    _fullNameController = TextEditingController(text: u?.fullName ?? '');
    _pinController = TextEditingController(text: u?.pinCode ?? '');
    _passwordController = TextEditingController();
    _selectedRoleName = (u != null && u.roles.isNotEmpty)
        ? u.roles.first
        : (widget.roles.isNotEmpty ? widget.roles.first.name : 'Кассир');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final selectedRole = widget.roles.where((r) => r.name == _selectedRoleName).firstOrNull ??
        (widget.roles.isNotEmpty ? widget.roles.first : null);
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
    return MynixDialog(
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
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: widget.roles.any((r) => r.name == _selectedRoleName)
                  ? _selectedRoleName
                  : (widget.roles.isNotEmpty ? widget.roles.first.name : null),
              decoration: const InputDecoration(labelText: 'Роль', border: OutlineInputBorder()),
              items: widget.roles
                  .map((r) => DropdownMenuItem(
                        value: r.name,
                        child: Row(
                          children: [
                            Icon(RoleFormatter.getRoleIcon(r.name), size: 18, color: RoleFormatter.getRoleColor(r.name)),
                            const SizedBox(width: 8),
                            Text(RoleFormatter.formatName(r.name)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRoleName = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          label: _isEdit ? 'Сохранить' : 'Создать',
          onPressed: _submit,
        ),
      ],
    );
  }
}
