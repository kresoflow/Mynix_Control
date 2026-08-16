import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/has_permission.dart';
import 'package:mynix_frontend/features/kitchen/view/kds_board.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return HasPermission(
      permission: 'kitchen:view',
      fallback: Center(
        child: Text(
          'У вас нет доступа к кухонному экрану.',
          style: AppTextStyles.h2.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      ),
      child: const KdsBoard(),
    );
  }
}
