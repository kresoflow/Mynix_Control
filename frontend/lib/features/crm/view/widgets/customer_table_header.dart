import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class CustomerTableHeader extends StatelessWidget {
  const CustomerTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Avatar spacing (40px) + Gap (14px)
          const SizedBox(width: 54),

          // Guest & Contact
          Expanded(
            flex: 3,
            child: Text(
              'ГОСТЬ / ТЕЛЕФОН',
              style: AppTextStyles.caption.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // LTV & Purchases
          Expanded(
            flex: 2,
            child: Text(
              'LTV / ЗАКАЗЫ',
              style: AppTextStyles.caption.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Bonuses
          SizedBox(
            width: 90,
            child: Text(
              'БОНУСЫ',
              style: AppTextStyles.caption.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Balance / Debt
          SizedBox(
            width: 120,
            child: Text(
              'САЛЬДО / ДЕПОЗИТ',
              style: AppTextStyles.caption.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Actions
          SizedBox(
            width: 70,
            child: Text(
              'ДЕЙСТВИЯ',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
