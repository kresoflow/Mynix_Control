import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
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
                  onTap: () => UserFormDialog.show(
                    context: context,
                    isDark: isDark,
                    roles: state.roles,
                  ),
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
              const Center(child: Text('Нет сотрудников'))
            else
              SettingsCard(
                isDark: isDark,
                children: [
                  for (int i = 0; i < state.users.length; i++) ...[
                    SettingsRow(
                      isDark: isDark,
                      title: '${state.users[i].fullName} (${state.users[i].roles.join(', ')})',
                      subtitle: 'Логин: ${state.users[i].username}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
                            onPressed: () => UserFormDialog.show(
                              context: context,
                              isDark: isDark,
                              roles: state.roles,
                              userToEdit: state.users[i],
                            ),
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
}
