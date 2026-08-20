import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/theme/app_logo_base64.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'icon_btn.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_shift_hub_modal.dart';
import 'package:mynix_frontend/features/pos/view/widgets/open_shift_modal.dart';

class MynixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCashTap;
  final VoidCallback onToggleSidebar;

  const MynixAppBar({super.key, required this.onCashTap, required this.onToggleSidebar});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggleSidebar,
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.list,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Image.memory(
                    AppLogoData.bytes,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kreso Flow',
                    style: AppTextStyles.h2.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          BlocBuilder<ShiftBloc, ShiftState>(
            builder: (context, state) {
              final isOpen = state is ShiftOpen;
              final isUnlocked = isOpen && state.isFinancialsUnlocked;
              final cash = (isOpen && isUnlocked)
                  ? ((state.shiftDetails['current_cash_expected'] ?? state.shiftDetails['opening_cash'] ?? 0) as num).toCurrency(context)
                  : null;

              return GestureDetector(
                onTap: onCashTap,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppColors.brandTertiary.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOpen
                            ? AppColors.brandTertiary.withValues(alpha: 0.35)
                            : AppColors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOpen ? AppColors.brandTertiary : AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOpen
                              ? (isUnlocked ? 'Смена • $cash' : 'Смена открыта')
                              : 'Смена закрыта',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? AppColors.brandTertiary : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          BlocBuilder<PosSettingsCubit, PosSettingsState>(
            builder: (context, posSettings) {
              return IconBtn(
                icon: PhosphorIconsRegular.palette,
                tooltip: posSettings.enableRainbowColors ? 'Отключить радужные цвета' : 'Включить радужные цвета',
                color: posSettings.enableRainbowColors ? AppColors.brandPrimary : null,
                onPressed: () => context.read<PosSettingsCubit>().toggleRainbowColors(),
              );
            },
          ),
          const SizedBox(width: 8),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isCurrentDark = themeState.isDark(context);
              return IconBtn(
                icon: isCurrentDark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
                tooltip: isCurrentDark ? 'Переключить на светлую тему' : 'Переключить на тёмную тему',
                onPressed: () => context.read<ThemeBloc>().add(ToggleThemeMode()),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildProfileMenu(context, isDark),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, bool isDark) {
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
        if (value == 'close_shift') {
          final state = context.read<ShiftBloc>().state;
          if (state is ShiftOpen) {
            showShiftHubModal(context, initialTab: 1);
          } else {
            showOpenShiftDialog(context);
          }
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

