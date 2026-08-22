import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/role_formatter.dart';
import 'package:mynix_frontend/core/widgets/profile/user_profile_modal.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_state.dart';
import 'package:mynix_frontend/features/pos/view/widgets/pos_shift_hub_modal.dart';
import 'package:mynix_frontend/features/pos/view/widgets/open_shift_modal.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';

class MobileNavDrawer extends StatelessWidget {
  final String location;

  const MobileNavDrawer({super.key, required this.location});

  static const _navItems = [
    (icon: PhosphorIconsRegular.receipt, label: 'Касса (POS)', route: '/pos'),
    (icon: PhosphorIconsRegular.cookingPot, label: 'Кухня (KDS)', route: '/kitchen'),
    (icon: PhosphorIconsRegular.clockCounterClockwise, label: 'История заказов', route: '/orders'),
    (icon: PhosphorIconsRegular.bookOpenText, label: 'Каталог меню', route: '/catalog'),
    (icon: PhosphorIconsRegular.package, label: 'Склад & Приходы', route: '/warehouse'),
    (icon: PhosphorIconsRegular.users, label: 'CRM & Гости', route: '/crm'),
    (icon: PhosphorIconsRegular.chartLineUp, label: 'Аналитика', route: '/analytics'),
    (icon: PhosphorIconsRegular.gear, label: 'Настройки', route: '/settings'),
  ];

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

    final settingsState = context.watch<SettingsBloc>().state;
    final showKds = settingsState.useKds && settingsState.showKdsInNav;
    final showOrders = settingsState.useOrders;

    final visibleNavItems = _navItems.where((item) {
      if (item.route == '/kitchen' && !showKds) return false;
      if (item.route == '/orders' && !showOrders) return false;
      return true;
    }).toList();

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
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
                        Text(fullName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold), maxLines: 1),
                        if (tenantName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsRegular.storefront, size: 12, color: AppColors.darkSubtext),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  tenantName,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        RoleFormatter.buildBadge(role),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Cash Shift Quick Action Button
            BlocBuilder<ShiftBloc, ShiftState>(
              builder: (context, state) {
                final isOpen = state is ShiftOpen;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      if (isOpen) {
                        showShiftHubModal(context);
                      } else {
                        showOpenShiftDialog(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.brandTertiary.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isOpen ? AppColors.brandTertiary.withValues(alpha: 0.35) : AppColors.danger.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(isOpen ? PhosphorIconsRegular.cashRegister : PhosphorIconsRegular.lockSimple, size: 18, color: isOpen ? AppColors.brandTertiary : AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isOpen ? 'Кассовая смена открыта' : 'Смена закрыта (Открыть)',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: isOpen ? AppColors.brandTertiary : AppColors.danger),
                            ),
                          ),
                          const Icon(PhosphorIconsRegular.caretRight, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: visibleNavItems.length,
                itemBuilder: (context, index) {
                  final item = visibleNavItems[index];
                  final isSelected = location.startsWith(item.route);

                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    selected: isSelected,
                    selectedTileColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                    leading: Icon(item.icon, color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    title: Text(
                      item.label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.brandPrimary : null,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item.route);
                    },
                  );
                },
              ),
            ),

            // Footer actions
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
            ListTile(
              dense: true,
              leading: Icon(PhosphorIconsRegular.userGear, color: AppColors.brandPrimary),
              title: const Text('Мой профиль и PIN'),
              onTap: () {
                Navigator.pop(context);
                showUserProfileModal(context);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(PhosphorIconsRegular.signOut, color: AppColors.danger),
              title: const Text('Выйти', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(LoggedOut());
              },
            ),
          ],
        ),
      ),
    );
  }
}
