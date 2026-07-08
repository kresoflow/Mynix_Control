import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PosEmptyCart extends StatelessWidget {
  const PosEmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.shoppingBag,
            size: 48,
            color: AppColors.darkSubtext.withValues(alpha: 0.4),
          ),
          SizedBox(height: 16),
          Text(
            'Заказ пуст',
            style: AppTextStyles.h3.copyWith(color: AppColors.darkSubtext),
          ),
          SizedBox(height: 6),
          Text(
            'Выберите блюда из меню',
            style: AppTextStyles.caption,
          ),
        ],
      ),
      ),
    );
  }
}
