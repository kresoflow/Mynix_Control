import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class CustomerKpiCards extends StatelessWidget {
  final int totalCount;
  final double totalDebt;
  final double totalDeposit;
  final double totalLtv;
  final double totalBonuses;
  final int debtorsCount;
  final int vipCount;

  const CustomerKpiCards({
    super.key,
    required this.totalCount,
    required this.totalDebt,
    required this.totalDeposit,
    required this.totalLtv,
    required this.totalBonuses,
    required this.debtorsCount,
    required this.vipCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        final cards = [
          _buildCard(
            title: 'LTV Базы (Выручка)',
            value: '${totalLtv.toStringAsFixed(0)} с',
            subtitle: '$vipCount VIP гостей',
            icon: PhosphorIconsRegular.chartLineUp,
            color: AppColors.brandPrimary,
            isDark: isDark,
          ),
          _buildCard(
            title: 'Бонусный фонд',
            value: '${totalBonuses.toStringAsFixed(0)} бонусов',
            subtitle: 'На балансе клиентов',
            icon: PhosphorIconsRegular.gift,
            color: Colors.amber,
            isDark: isDark,
          ),
          _buildCard(
            title: 'Долг гостей',
            value: totalDebt > 0 ? '- ${totalDebt.toStringAsFixed(0)} с' : '0 с',
            subtitle: '$debtorsCount должников',
            icon: PhosphorIconsRegular.trendDown,
            color: totalDebt > 0 ? AppColors.error : AppColors.darkSubtext,
            isDark: isDark,
          ),
          _buildCard(
            title: 'Всего в базе',
            value: '$totalCount',
            subtitle: 'Активных гостей',
            icon: PhosphorIconsRegular.users,
            color: Colors.cyanAccent,
            isDark: isDark,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.7) : AppColors.textSecondaryLight.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
