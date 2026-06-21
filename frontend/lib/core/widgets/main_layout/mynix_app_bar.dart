import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:retail_os_frontend/core/theme/theme_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:retail_os_frontend/features/pos/bloc/shift_state.dart';
import 'icon_btn.dart';

class MynixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCashTap;

  const MynixAppBar({super.key, required this.onCashTap});

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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.logoGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'M',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0E1016),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Mynix Control',
            style: AppTextStyles.h2.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const Spacer(),

          BlocBuilder<ShiftBloc, ShiftState>(
            builder: (context, state) {
              final isOpen = state is ShiftOpen;
              final cash = isOpen
                  ? '${state.shiftDetails['current_cash_expected'] ?? state.shiftDetails['opening_cash']} с'
                  : 'Закрыто';

              return GestureDetector(
                onTap: onCashTap,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppColors.brandTertiary.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOpen
                            ? AppColors.brandTertiary.withValues(alpha: 0.3)
                            : AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 16,
                          color: isOpen ? AppColors.brandTertiary : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cash,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
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

          IconBtn(
            icon: Icons.wb_sunny_outlined,
            tooltip: 'Переключить тему',
            onPressed: () => context.read<ThemeBloc>().add(ThemeEvent.toggleTheme),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
