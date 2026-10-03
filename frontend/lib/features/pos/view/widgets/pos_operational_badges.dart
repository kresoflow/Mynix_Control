// ==============================================================================
// МОДУЛЬ: POS / Операционные кнопки зала (Столики и Входящие заказы)
// ДОМЕН: lib/features/pos/view/widgets/pos_operational_badges.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:kreso_frontend/features/auth/bloc/auth_state.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'tables/pos_active_tables_dialog.dart';
import 'dialogs/incoming_orders_dialog.dart';

// ── Виджет оперативных кнопок зала ───────────────────────────────────────────

class PosOperationalBadges extends StatelessWidget {
  final double size;

  const PosOperationalBadges({
    super.key,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final isWaiter = authState is AuthAuthenticated && authState.role.toLowerCase() == 'waiter';

    return BlocBuilder<PosTabCubit, PosTabState>(
      builder: (context, tabState) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Кнопка активных столиков
            _buildActiveTablesButton(context, tabState.activeTablesCount, isDark),
            const SizedBox(width: 8),

            // 2. Кнопка входящих заказов с зала
            _buildIncomingOrdersButton(context, tabState.incomingCount, isWaiter, isDark),
          ],
        );
      },
    );
  }

  // ── Кнопка столиков ────────────────────────────────────────────────────────

  Widget _buildActiveTablesButton(BuildContext context, int count, bool isDark) {
    final hasTables = count > 0;
    final primary = AppColors.brandPrimary;
    final bg = hasTables
        ? primary.withValues(alpha: isDark ? 0.16 : 0.12)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final borderColor = hasTables
        ? primary.withValues(alpha: isDark ? 0.5 : 0.6)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final iconColor = hasTables ? primary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return Tooltip(
      message: 'Активные столики зала ($count)',
      child: InkWell(
        onTap: () => PosActiveTablesDialog.show(context).then((_) {
          if (context.mounted) {
            context.read<PosTabCubit>().refreshCounts();
          }
        }),
        borderRadius: BorderRadius.circular(10),
        child: Badge(
          isLabelVisible: hasTables,
          backgroundColor: primary,
          textColor: Colors.white,
          label: Text(
            '$count',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          offset: const Offset(3, -3),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Icon(
              hasTables ? PhosphorIconsBold.chair : PhosphorIconsRegular.chair,
              size: size > 34 ? 18 : 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── Кнопка входящих заказов ────────────────────────────────────────────────

  Widget _buildIncomingOrdersButton(BuildContext context, int count, bool isWaiter, bool isDark) {
    final hasPending = count > 0;
    final badgeColor = isWaiter ? AppColors.brandPrimary : AppColors.warning;
    final tooltipLabel = isWaiter ? 'Мои заказы с зала ($count)' : 'Входящие заказы с зала ($count)';
    final icon = isWaiter
        ? (hasPending ? PhosphorIconsBold.receipt : PhosphorIconsRegular.receipt)
        : (hasPending ? PhosphorIconsBold.bellRinging : PhosphorIconsRegular.bell);

    final bg = hasPending
        ? badgeColor.withValues(alpha: isDark ? 0.16 : 0.12)
        : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final borderColor = hasPending
        ? badgeColor.withValues(alpha: isDark ? 0.5 : 0.6)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final iconColor = hasPending ? badgeColor : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return Tooltip(
      message: tooltipLabel,
      child: InkWell(
        onTap: () => IncomingOrdersDialog.show(context).then((_) {
          if (context.mounted) {
            context.read<PosTabCubit>().refreshCounts();
          }
        }),
        borderRadius: BorderRadius.circular(10),
        child: Badge(
          isLabelVisible: hasPending,
          backgroundColor: badgeColor,
          textColor: Colors.white,
          label: Text(
            '$count',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          offset: const Offset(3, -3),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Icon(
              icon,
              size: size > 34 ? 18 : 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
