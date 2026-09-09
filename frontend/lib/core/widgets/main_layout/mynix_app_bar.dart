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
import 'package:mynix_frontend/features/pos/view/widgets/sync_status_badge.dart';
import 'icon_btn.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'app_bar_profile_menu.dart';

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
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Sidebar Toggle & Brand
          IconButton(
            icon: const Icon(PhosphorIconsRegular.list, size: 20),
            tooltip: 'Меню навигации',
            onPressed: onToggleSidebar,
          ),
          const SizedBox(width: 8),
          Image.memory(
            AppLogoData.bytes,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(
            'Kreso Flow',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),

          // 2. Network Sync Status & Shift
          const SyncStatusBadge(),
          const SizedBox(width: 12),
          BlocBuilder<ShiftBloc, ShiftState>(
            builder: (context, state) {
              final isOpen = state is ShiftOpen;
              final isUnlocked = isOpen && state.isFinancialsUnlocked;
              final cash = (isOpen && isUnlocked)
                  ? ((state.shiftDetails['current_cash_expected'] ?? state.shiftDetails['opening_cash'] ?? 0) as num).toCurrency(context)
                  : null;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCashTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOpen ? AppColors.success.withValues(alpha: 0.35) : AppColors.danger.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOpen ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOpen
                              ? (isUnlocked && cash != null ? 'Смена • $cash' : 'Смена открыта')
                              : 'Смена закрыта',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? AppColors.success : AppColors.danger,
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

          // 3. Theme
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

          // 4. Profile Menu
          const AppBarProfileMenu(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
