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
        final isNarrow = constraints.maxWidth < 900;
        final cards = [
          _buildCard(
            title: 'LTV Базы (Выручка)',
            value: '${totalLtv.toStringAsFixed(0)} с',
            subtitle: '$vipCount VIP гостей (LTV > 10k)',
            icon: PhosphorIconsRegular.chartLineUp,
            color: AppColors.brandPrimary,
            isDark: isDark,
          ),
          _buildCard(
            title: 'Бонусный фонд',
            value: '${totalBonuses.toStringAsFixed(0)} бонусов',
            subtitle: 'На счетах гостей',
            icon: PhosphorIconsRegular.gift,
            color: Colors.amber,
            isDark: isDark,
          ),
          _buildCard(
            title: 'Долг гостей',
            value: '- ${totalDebt.toStringAsFixed(2)} с',
            subtitle: '$debtorsCount должников',
            icon: PhosphorIconsRegular.trendDown,
            color: AppColors.error,
            isDark: isDark,
          ),
          _buildCard(
            title: 'Всего в базе',
            value: '$totalCount',
            subtitle: 'Гостей в CRM',
            icon: PhosphorIconsRegular.users,
            color: Colors.blueAccent,
            isDark: isDark,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
