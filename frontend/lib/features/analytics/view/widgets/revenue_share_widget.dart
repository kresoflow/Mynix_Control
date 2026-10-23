import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';

class RevenueShareWidget extends StatelessWidget {
  final double dishesRevenue;
  final double retailRevenue;
  final double totalRevenue;

  const RevenueShareWidget({
    super.key,
    required this.dishesRevenue,
    required this.retailRevenue,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dishesShare = totalRevenue > 0 ? (dishesRevenue / totalRevenue) : 0.5;
    final retailShare = totalRevenue > 0 ? (retailRevenue / totalRevenue) : 0.5;

    final dishesColor = AppColors.brandPrimary;
    final retailColor = AppColors.brandSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Структура выручки',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 28),
          
          // Progress bar with Neon Glow
          Container(
            height: 18,
            decoration: BoxDecoration(
              borderRadius: AppRadii.radiusLg,
              boxShadow: [
                ...AppShadows.glow(dishesColor),
                ...AppShadows.glow(retailColor),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadii.radiusLg,
              child: Row(
                children: [
                  Expanded(
                    flex: (dishesShare * 100).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            dishesColor.withValues(alpha: 0.8),
                            dishesColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (retailShare * 100).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            retailColor,
                            retailColor.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(
                context: context,
                color: dishesColor,
                title: 'Блюда',
                value: dishesRevenue,
                share: dishesShare,
                isDark: isDark,
              ),
              _buildLegendItem(
                context: context,
                color: retailColor,
                title: 'Витрина',
                value: retailRevenue,
                share: retailShare,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required BuildContext context,
    required Color color,
    required String title,
    required double value,
    required double share,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: AppShadows.dotGlow(color, opacity: 0.6, blur: 10),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(0)} ${context.watch<SettingsBloc>().state.currency} (${(share * 100).toStringAsFixed(1)}%)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
