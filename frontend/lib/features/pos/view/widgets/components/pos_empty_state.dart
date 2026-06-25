import 'package:flutter/material.dart';
import 'package:retail_os_frontend/core/theme/app_colors.dart';
import 'package:retail_os_frontend/core/theme/app_text_styles.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PosEmptyState extends StatelessWidget {
  final bool inCategory;

  const PosEmptyState({
    super.key,
    required this.inCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inCategory ? PhosphorIconsRegular.hamburger : PhosphorIconsRegular.bookOpen,
            size: 52,
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.darkSubtext.withValues(alpha: 0.35)
                : AppColors.lightSubtext.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            inCategory ? 'В категории нет товаров' : 'Меню не загружено',
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkSubtext 
                  : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
