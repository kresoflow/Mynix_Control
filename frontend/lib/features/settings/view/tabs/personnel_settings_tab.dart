import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/role_formatter.dart';
import 'package:mynix_frontend/features/settings/bloc/user_bloc.dart';
import 'package:mynix_frontend/features/settings/repository/user_repository.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_ui_components.dart';
import 'package:mynix_frontend/features/settings/view/widgets/user_form_dialog.dart';

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

        final ownerUsers = state.users.where((u) {
          return u.roles.any((r) => r.toLowerCase().contains('owner') || r.toLowerCase().contains('superadmin'));
        }).toList();

        final staffUsers = state.users.where((u) {
          return !u.roles.any((r) => r.toLowerCase().contains('owner') || r.toLowerCase().contains('superadmin'));
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(40),
          children: [
            Text(
              'Управление персоналом',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 24),

            // ── 1. Владелец заведения (VIP Card) ──────────────────────
            Text(
              'Владелец заведения',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
            const SizedBox(height: 10),

            if (ownerUsers.isEmpty)
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

            const SizedBox(height: 36),

            // ── 2. Штат сотрудников (Линейный персонал) ───────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Штат сотрудников (${staffUsers.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                InkWell(
                  onTap: () => UserFormDialog.show(
                    context: context,
                    isDark: isDark,
                    roles: state.roles,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.plus, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Добавить сотрудника',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (staffUsers.isEmpty)
              SettingsCard(
                isDark: isDark,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Нет добавленных сотрудников (кассиров, поваров, управляющих)'),
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
                            icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
                            tooltip: 'Удалить сотрудника',
                            onPressed: () {
                              context.read<UserBloc>().add(DeleteUser(staffUsers[i].id));
                            },
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
}
