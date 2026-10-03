import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/theme_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_state.dart';
import 'package:kreso_frontend/features/pos/view/widgets/pos_shift_hub_modal.dart';
import 'package:kreso_frontend/features/pos/view/widgets/open_shift_modal.dart';
import 'package:kreso_frontend/core/utils/role_formatter.dart';
import 'package:kreso_frontend/core/widgets/profile/user_profile_modal.dart';
import 'package:kreso_frontend/core/widgets/logout_confirm_dialog.dart';

class AppBarProfileMenu extends StatelessWidget {
  final VoidCallback? onShiftTap;

  const AppBarProfileMenu({super.key, this.onShiftTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final shiftState = context.watch<ShiftBloc>().state;
    final isShiftOpen = shiftState is ShiftOpen;

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
      tooltip: 'Профиль и смена',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isShiftOpen ? AppColors.success : AppColors.danger,
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      onSelected: (value) {
        if (value == 'shift') {
          if (onShiftTap != null) {
            onShiftTap!();
          } else {
            if (isShiftOpen) {
              showShiftHubModal(context);
            } else {
              showOpenShiftDialog(context);
            }
          }
        } else if (value == 'profile') {
          showUserProfileModal(context);
        } else if (value == 'theme') {
          context.read<ThemeBloc>().add(ToggleThemeMode());
        } else if (value == 'logout') {
          showLogoutConfirmDialog(context);
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.storefront, size: 13, color: AppColors.darkSubtext),
                    const SizedBox(width: 4),
                    Text(
                      tenantName,
                      style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext, fontSize: 11),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              RoleFormatter.buildBadge(role),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'shift',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isShiftOpen ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Кассовая смена', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      isShiftOpen ? 'Смена открыта' : 'Смена закрыта',
                      style: AppTextStyles.caption.copyWith(
                        color: isShiftOpen ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight, size: 14, color: AppColors.darkSubtext),
            ],
          ),
        ),
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
          value: 'theme',
          child: Row(
            children: [
              Icon(
                isDark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
                color: AppColors.brandPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                isDark ? 'Светлая тема' : 'Тёмная тема',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.signOut, color: AppColors.danger, size: 20),
              const SizedBox(width: 12),
              Text('Выйти из аккаунта', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
