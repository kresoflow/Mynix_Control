// ==============================================================================
// МОДУЛЬ: Навигация / Глобальная шапка приложения (AppNavBar)
// ДОМЕН: lib/core/widgets/main_layout/app_nav_bar.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/theme/app_logo_base64.dart';
import 'package:kreso_frontend/core/theme/theme_bloc.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_segmented_control.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'package:kreso_frontend/features/pos/view/widgets/pos_operational_badges.dart';
import 'package:kreso_frontend/features/pos/view/widgets/sync_status_badge.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'icon_btn.dart';
import 'app_bar_profile_menu.dart';

// ── Глобальная шапка приложения ───────────────────────────────────────────────

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCashTap;
  final VoidCallback onToggleSidebar;
  final String? location;

  const AppNavBar({
    super.key,
    required this.onCashTap,
    required this.onToggleSidebar,
    this.location,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final isPosRoute = location == null || location!.startsWith('/pos');
    final isOrdersRoute = location?.startsWith('/orders') == true;
    final showOperationalBadges = isPosRoute || isOrdersRoute;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Бренд и кнопка бокового меню
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

          // 2. Центр: переключатель режимов POS (Касса / Заказы / Кухня)
          if (isPosRoute) ...[
            _buildPosSegmentedControl(context),
            const Spacer(),
          ],

          // 3. Операционный блок зала (Столики и Входящие заказы)
          if (showOperationalBadges) ...[
            const PosOperationalBadges(size: 38),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 20,
              color: borderColor,
            ),
            const SizedBox(width: 12),
          ],

          // 4. Сетевой статус синхронизации
          const SyncStatusBadge(),
          const SizedBox(width: 12),

          // 5. Переключатель светлой / тёмной темы
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

          // 6. Профиль и статус смены
          AppBarProfileMenu(onShiftTap: onCashTap),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Центр: Сегментированный переключатель вкладок POS ──────────────────────

  Widget _buildPosSegmentedControl(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final useOrders = settingsState.useOrders;
    final useKds = settingsState.useKds;

    return BlocBuilder<PosTabCubit, PosTabState>(
      builder: (context, tabState) {
        return AppSegmentedControl<int>(
          selectedValue: tabState.currentTab,
          onValueChanged: (val) => context.read<PosTabCubit>().setTab(val),
          size: AppSegmentedSize.md,
          items: [
            const AppSegmentedItem(
              value: 0,
              label: 'Касса',
              icon: PhosphorIconsRegular.receipt,
            ),
            if (useOrders)
              const AppSegmentedItem(
                value: 1,
                label: 'Заказы',
                icon: PhosphorIconsRegular.listNumbers,
              ),
            if (useKds)
              const AppSegmentedItem(
                value: 2,
                label: 'Кухня (KDS)',
                icon: PhosphorIconsRegular.cookingPot,
              ),
          ],
        );
      },
    );
  }
}
