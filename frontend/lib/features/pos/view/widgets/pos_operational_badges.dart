// ==============================================================================
// МОДУЛЬ: POS / Операционные кнопки зала (Активные столики)
// ДОМЕН: lib/features/pos/view/widgets/pos_operational_badges.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'tables/pos_active_tables_dialog.dart';

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

    return BlocBuilder<PosTabCubit, PosTabState>(
      builder: (context, tabState) {
        return _buildActiveTablesButton(context, tabState.activeTablesCount, isDark);
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
        borderRadius: AppRadii.radiusMd,
        child: Badge(
          isLabelVisible: hasTables,
          backgroundColor: primary,
          textColor: AppColors.white,
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
              borderRadius: AppRadii.radiusMd,
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
}
