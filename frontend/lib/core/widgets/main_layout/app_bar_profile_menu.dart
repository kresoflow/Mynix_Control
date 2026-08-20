import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/core/utils/role_formatter.dart';
import 'package:mynix_frontend/core/widgets/profile/user_profile_modal.dart';

class AppBarProfileMenu extends StatelessWidget {
  const AppBarProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    String fullName = 'Сотрудник';
    String role = 'staff';
    String tenantName = '';
    if (authState is AuthAuthenticated) {
      fullName = authState.fullName.isNotEmpty
          ? authState.fullName
          : (authState.username.isNotEmpty ? '@${authState.username}' : 'Сотрудник');
      role = authState.role;
      tenantName = authState.tenantName;
    }

    return PopupMenuButton<String>(
      tooltip: 'Профиль пользователя',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 8,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(PhosphorIconsRegular.user, size: 20, color: AppColors.brandPrimary),
        ),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          showUserProfileModal(context);
        } else if (value == 'logout') {
          context.read<AuthBloc>().add(LoggedOut());
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              if (tenantName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '🏢 $tenantName',
                  style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext, fontSize: 11),
                ),
              ],
              const SizedBox(height: 6),
              RoleFormatter.buildBadge(role),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.userCircle, color: AppColors.brandPrimary, size: 20),
              const SizedBox(width: 12),
              Text('Мой профиль и PIN', style: AppTextStyles.body),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.signOut, color: AppColors.darkSubtext, size: 20),
              const SizedBox(width: 12),
              Text('Выйти из аккаунта', style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}
