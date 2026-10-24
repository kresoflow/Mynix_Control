// ==============================================================================
// МОДУЛЬ: Настройки / Вкладка персонала и управления доступом
// ДОМЕН: lib/features/settings/view/tabs/personnel_settings_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/core/utils/role_formatter.dart';
import 'package:kreso_frontend/features/settings/models/user_model.dart';
import 'package:kreso_frontend/features/settings/bloc/user_bloc.dart';
import 'package:kreso_frontend/features/settings/repository/user_repository.dart';
import 'package:kreso_frontend/features/settings/view/widgets/settings_ui_components.dart';
import 'package:kreso_frontend/features/settings/view/widgets/user_form_dialog.dart';

class PersonnelSettingsTab extends StatefulWidget {
  final bool isDark;
  final UserBloc? userBloc;

  const PersonnelSettingsTab({
    super.key,
    required this.isDark,
    this.userBloc,
  });

  @override
  State<PersonnelSettingsTab> createState() => _PersonnelSettingsTabState();
}

class _PersonnelSettingsTabState extends State<PersonnelSettingsTab> {
  UserBloc? _internalUserBloc;

  UserBloc get _effectiveBloc => widget.userBloc ?? _internalUserBloc!;

  @override
  void initState() {
    super.initState();
    if (widget.userBloc == null) {
      _internalUserBloc = UserBloc(repository: UserRepository())..add(LoadUsers());
    }
  }

  @override
  void dispose() {
    _internalUserBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _effectiveBloc,
      child: _PersonnelSettingsView(isDark: widget.isDark),
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
        final isInitialLoading = state.isLoading && state.users.isEmpty;

        final ownerUsers = state.users.where((u) {
          return u.roles.any((r) => r.toLowerCase().contains('owner') || r.toLowerCase().contains('superadmin'));
        }).toList();

        final staffUsers = state.users.where((u) {
          return !u.roles.any((r) => r.toLowerCase().contains('owner') || r.toLowerCase().contains('superadmin'));
        }).toList();

        final isMobile = MediaQuery.of(context).size.width < 700;
        return ListView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          children: [
            AppPageHeader(
              title: 'Управление персоналом',
              subtitle: 'Сотрудники, роли и уровни доступа в системе',
              actions: [
                AppPrimaryButton(
                  label: 'Добавить сотрудника',
                  icon: PhosphorIconsRegular.plus,
                  size: AppButtonSize.md,
                  onPressed: isInitialLoading ? null : () => UserFormDialog.show(
                    context: context,
                    isDark: isDark,
                    roles: state.roles,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SettingsSectionHeader(
              title: 'Владелец заведения',
              isDark: isDark,
              subtitle: 'Главный аккаунт с полными правами доступа',
            ),
            const SizedBox(height: 12),

            if (isInitialLoading)
              SettingsCard(
                isDark: isDark,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Загрузка персонала...',
                            style: TextStyle(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (ownerUsers.isEmpty)
              SettingsCard(
                isDark: isDark,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Владелец заведения не указан'),
                  ),
                ],
              )
            else
              SettingsCard(
                isDark: isDark,
                children: [
                  for (int i = 0; i < ownerUsers.length; i++) ...[
                    SettingsRow(
                      isDark: isDark,
                      title: ownerUsers[i].fullName.isNotEmpty ? ownerUsers[i].fullName : '@${ownerUsers[i].username}',
                      subtitle: 'Логин: @${ownerUsers[i].username} • PIN: ${ownerUsers[i].pinCode != null && ownerUsers[i].pinCode!.isNotEmpty ? '••••' : '1234'}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RoleFormatter.buildBadge('owner'),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
                            tooltip: 'Редактировать владельца',
                            onPressed: () => UserFormDialog.show(
                              context: context,
                              isDark: isDark,
                              roles: state.roles,
                              userToEdit: ownerUsers[i],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < ownerUsers.length - 1)
                      SettingsDivider(isDark: isDark),
                  ],
                ],
              ),

            const SizedBox(height: 32),

            SettingsSectionHeader(
              title: 'Штат сотрудников (${staffUsers.length})',
              isDark: isDark,
              subtitle: 'Кассиры, управляющие и линейный персонал',
            ),
            const SizedBox(height: 12),

            if (isInitialLoading)
              SettingsCard(
                isDark: isDark,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Загрузка сотрудников...',
                            style: TextStyle(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (staffUsers.isEmpty)
              SettingsCard(
                isDark: isDark,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Нет добавленных сотрудников (кассиров, управляющих)'),
                    ),
                  ),
                ],
              )
            else
              SettingsCard(
                isDark: isDark,
                children: [
                  for (int i = 0; i < staffUsers.length; i++) ...[
                    SettingsRow(
                      isDark: isDark,
                      title: staffUsers[i].fullName.isNotEmpty ? staffUsers[i].fullName : '@${staffUsers[i].username}',
                      subtitle: 'Логин: @${staffUsers[i].username} • PIN: ${staffUsers[i].pinCode != null && staffUsers[i].pinCode!.isNotEmpty ? '••••' : '1234'}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RoleFormatter.buildBadge(staffUsers[i].roles.isNotEmpty ? staffUsers[i].roles.first : 'staff'),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
                            tooltip: 'Редактировать',
                            onPressed: () => UserFormDialog.show(
                              context: context,
                              isDark: isDark,
                              roles: state.roles,
                              userToEdit: staffUsers[i],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.danger),
                            tooltip: 'Удалить сотрудника',
                            onPressed: () => _confirmDeleteUser(context, staffUsers[i]),
                          ),
                        ],
                      ),
                    ),
                    if (i < staffUsers.length - 1)
                      SettingsDivider(isDark: isDark),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(BuildContext context, StaffUser user) async {
    final name = user.fullName.isNotEmpty ? user.fullName : '@${user.username}';
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Удалить сотрудника?',
      message: 'Вы уверены, что хотите удалить сотрудника «$name»?\nДоступ к кассе и системе будет немедленно заблокирован.',
      confirmLabel: 'Удалить',
      confirmIcon: PhosphorIconsRegular.trash,
      isDanger: true,
      icon: PhosphorIconsRegular.trash,
    );
    if (confirmed == true && context.mounted) {
      context.read<UserBloc>().add(DeleteUser(user.id));
    }
  }
}
