import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/settings/models/user_model.dart';
import 'package:mynix_frontend/features/settings/bloc/user_bloc.dart';
import 'package:mynix_frontend/features/settings/repository/user_repository.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_ui_components.dart';

class PersonnelSettingsTab extends StatelessWidget {
  final bool isDark;
  const PersonnelSettingsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc(repository: UserRepository())..add(LoadUsers()),
      child: _PersonnelSettingsView(isDark: isDark),
    );
  }
}

class _PersonnelSettingsView extends StatelessWidget {
  final bool isDark;
  const _PersonnelSettingsView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(40),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              children: [
                Text(
                  'Управление персоналом',
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                InkWell(
                  onTap: () => _showAddUserDialog(context, isDark, state.roles),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+ Добавить сотрудника',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (state.users.isEmpty)
              const Center(child: Text("Нет сотрудников"))
            else
              SettingsCard(
                isDark: isDark,
                children: [
                  for (int i = 0; i < state.users.length; i++) ...[
                    SettingsRow(
                      isDark: isDark,
                      title: '${state.users[i].fullName} (${state.users[i].roles.join(", ")})',
                      subtitle: 'Логин: ${state.users[i].username}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
                            onPressed: () => _showEditUserDialog(context, isDark, state.roles, state.users[i]),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                            onPressed: () {
                              context.read<UserBloc>().add(DeleteUser(state.users[i].id));
                            },
                          ),
                        ],
                      ),
                    ),
                    if (i < state.users.length - 1)
                      SettingsDivider(isDark: isDark),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }


  void _showEditUserDialog(BuildContext parentContext, bool isDark, List<Role> availableRoles, StaffUser user) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: parentContext.read<UserBloc>(),
          child: _EditUserDialog(isDark: isDark, roles: availableRoles, user: user),
        );
      },
    );
  }
  void _showAddUserDialog(BuildContext parentContext, bool isDark, List<Role> availableRoles) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: parentContext.read<UserBloc>(),
          child: _AddUserDialog(isDark: isDark, roles: availableRoles),
        );
      },
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final bool isDark;
  final List<Role> roles;
  const _AddUserDialog({required this.isDark, required this.roles});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  int? _selectedRoleId;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: Text("Новый сотрудник", style: TextStyle(color: widget.isDark ? AppColors.darkText : AppColors.lightText)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: "ФИО (например: Анна Кассир)"),
            ),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: "Логин (например: anna_cash)"),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Пароль"),
            ),
            TextField(
              controller: _pinCtrl,
              decoration: const InputDecoration(labelText: "Пин-код (Опционально)"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedRoleId,
              decoration: const InputDecoration(labelText: "Роль"),
              items: widget.roles.map((r) {
                return DropdownMenuItem(value: r.id, child: Text(r.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRoleId = val;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_usernameCtrl.text.isEmpty || _fullNameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty || _selectedRoleId == null) {
              return;
            }
            context.read<UserBloc>().add(CreateUser(
              username: _usernameCtrl.text,
              fullName: _fullNameCtrl.text,
              password: _passwordCtrl.text,
              pinCode: _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null,
              roleIds: [_selectedRoleId!],
            ));
            Navigator.pop(context);
          },
          child: const Text("Создать"),
        ),
      ],
    );
  }
}


class _EditUserDialog extends StatefulWidget {
  final bool isDark;
  final List<Role> roles;
  final StaffUser user;
  const _EditUserDialog({required this.isDark, required this.roles, required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late TextEditingController _usernameCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _pinCtrl;
  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _fullNameCtrl = TextEditingController(text: widget.user.fullName);
    _passwordCtrl = TextEditingController();
    _pinCtrl = TextEditingController();
    
    // Attempt to match the existing role
    if (widget.user.roles.isNotEmpty) {
      final roleName = widget.user.roles.first;
      try {
        final role = widget.roles.firstWhere((r) => r.name == roleName);
        _selectedRoleId = role.id;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: Text("Редактировать сотрудника", style: TextStyle(color: widget.isDark ? AppColors.darkText : AppColors.lightText)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: "ФИО"),
            ),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: "Логин"),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Новый пароль (оставьте пустым, если не меняете)"),
            ),
            TextField(
              controller: _pinCtrl,
              decoration: const InputDecoration(labelText: "Новый Пин-код (оставьте пустым, если не меняете)"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedRoleId,
              decoration: const InputDecoration(labelText: "Роль"),
              items: widget.roles.map((r) {
                return DropdownMenuItem(value: r.id, child: Text(r.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRoleId = val;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_usernameCtrl.text.isEmpty || _fullNameCtrl.text.isEmpty) {
              return;
            }
            context.read<UserBloc>().add(UpdateUser(
              userId: widget.user.id,
              username: _usernameCtrl.text,
              fullName: _fullNameCtrl.text,
              password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
              pinCode: _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null,
              roleIds: _selectedRoleId != null ? [_selectedRoleId!] : null,
            ));
            Navigator.pop(context);
          },
          child: const Text("Сохранить"),
        ),
      ],
    );
  }
}
