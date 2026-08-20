import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/role_formatter.dart';
import 'package:mynix_frontend/core/widgets/profile/user_profile_modal.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';

class MobileSettingsUserHeader extends StatelessWidget {
  final bool isDark;

  const MobileSettingsUserHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Icon(PhosphorIconsRegular.user, size: 22, color: AppColors.brandPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tenantName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '🏢 $tenantName',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    RoleFormatter.buildBadge(role),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showUserProfileModal(context),
                  icon: Icon(PhosphorIconsRegular.userGear, size: 16, color: AppColors.brandPrimary),
                  label: const Text('Профиль и PIN', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.read<AuthBloc>().add(LoggedOut()),
                icon: const Icon(PhosphorIconsRegular.signOut, size: 16, color: AppColors.danger),
                label: const Text('Выйти', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
