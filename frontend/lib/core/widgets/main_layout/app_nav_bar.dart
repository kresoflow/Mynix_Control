import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_logo_base64.dart';
import 'package:kreso_frontend/core/theme/theme_bloc.dart';
import 'package:kreso_frontend/features/pos/view/widgets/sync_status_badge.dart';
import 'icon_btn.dart';
import 'app_bar_profile_menu.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCashTap;
  final VoidCallback onToggleSidebar;

  const AppNavBar({super.key, required this.onCashTap, required this.onToggleSidebar});

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

          // 2. Network Sync Status
          const SyncStatusBadge(),
          const SizedBox(width: 12),

          // 3. Theme Toggle
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

          // 4. Profile & Shift Menu
          AppBarProfileMenu(onShiftTap: onCashTap),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
