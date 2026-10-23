import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/features/pos/models/menu_category.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class MenuManagerBreadcrumbs extends StatelessWidget {
  final List<MenuCategory> navigationHistory;
  final VoidCallback onNavigateRoot;
  final Function(int) onNavigateUpTo;
  final VoidCallback onAddCategory;
  final VoidCallback? onAddMenuItem;

  const MenuManagerBreadcrumbs({
    super.key,
    required this.navigationHistory,
    required this.onNavigateRoot,
    required this.onNavigateUpTo,
    required this.onAddCategory,
    this.onAddMenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadii.radiusLg,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onNavigateRoot,
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.house, size: 20),
                const SizedBox(width: 8),
                Text('Главная', style: AppTextStyles.h3),
              ],
            ),
          ),
          ...List.generate(navigationHistory.length, (index) {
            final cat = navigationHistory[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    PhosphorIconsRegular.caretRight,
                    size: 20,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                InkWell(
                  onTap: () => onNavigateUpTo(index),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight: index == navigationHistory.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: index == navigationHistory.length - 1
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ],
            );
          }),
          const Spacer(),
          AppSecondaryButton(
            onPressed: onAddCategory,
            icon: PhosphorIconsRegular.folderPlus,
            label: 'Папка',
          ),
          if (onAddMenuItem != null) ...[
            const SizedBox(width: 12),
            AppPrimaryButton(
              onPressed: onAddMenuItem,
              icon: PhosphorIconsRegular.plusSquare,
              label: 'Товар',
            ),
          ],
        ],
      ),
    );
  }
}
