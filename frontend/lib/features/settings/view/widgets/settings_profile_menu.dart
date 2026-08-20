import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_dialogs.dart';

class SettingsProfileMenu extends StatelessWidget {
  final bool isDark;

  const SettingsProfileMenu({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Профиль пользователя',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 8,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(PhosphorIconsRegular.user, size: 24, color: AppColors.brandPrimary),
        ),
      ),
      onSelected: (value) {
        if (value == 'close_shift') {
          SettingsDialogs.showCloseShiftDialog(context);
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
              Text('Владелец платформы', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text('Полный доступ', style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'close_shift',
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.lockKey, color: AppColors.danger, size: 20),
              const SizedBox(width: 12),
              Text('Закрыть смену', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
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
