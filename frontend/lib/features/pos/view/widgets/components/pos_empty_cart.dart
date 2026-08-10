import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PosEmptyCart extends StatelessWidget {
  const PosEmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : AppColors.brandPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsRegular.shoppingCart,
                size: 64,
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : AppColors.brandPrimary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Корзина пуста',
              style: AppTextStyles.h2.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите блюда из меню слева,\nчтобы начать заказ',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
