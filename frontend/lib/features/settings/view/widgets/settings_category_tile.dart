import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class SettingsCategory {
  final IconData icon;
  final String title;

  const SettingsCategory(this.icon, this.title);
}

class SettingsCategoryTile extends StatelessWidget {
  final SettingsCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const SettingsCategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(category.icon, color: isSelected ? AppColors.brandPrimary : color, size: 24),
            const SizedBox(width: 16),
            Text(
              category.title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.darkText : AppColors.lightText)
                    : color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
