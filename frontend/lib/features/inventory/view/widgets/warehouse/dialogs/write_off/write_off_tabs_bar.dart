// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

// ==============================================================================
// 2. РЕЖИМЫ ОТОБРАЖЕНИЯ СПИСАНИЯ
// ==============================================================================
enum WriteOffViewMode {
  items, // По строкам (таблица + быстрый поиск)
  categories, // По категориям (аккордеоны цехов и складских зон)
}

// ==============================================================================
// 3. ТУЛБАР ПЕРЕКЛЮЧЕНИЯ РЕЖИМОВ СПИСАНИЯ
// ==============================================================================
/// [ИНВАРИАНТ] Переключатель между строчным и категорийным режимом списания.
class WriteOffTabsBar extends StatelessWidget {
  final WriteOffViewMode viewMode;
  final ValueChanged<WriteOffViewMode> onViewModeChanged;
  final int itemsCount;

  const WriteOffTabsBar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.itemsCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightBg,
            borderRadius: AppRadii.inputRadius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabPill(
                label: 'По позициям',
                icon: PhosphorIconsRegular.listDashes,
                isSelected: viewMode == WriteOffViewMode.items,
                onTap: () => onViewModeChanged(WriteOffViewMode.items),
                isDark: isDark,
              ),
              _buildTabPill(
                label: 'По категориям',
                icon: PhosphorIconsRegular.squaresFour,
                isSelected: viewMode == WriteOffViewMode.categories,
                onTap: () => onViewModeChanged(WriteOffViewMode.categories),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            viewMode == WriteOffViewMode.categories
                ? 'Каталог цехов и зон: массовое списание по группам товаров'
                : 'Построчный ввод: быстрый поиск и добавление позиций',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontSize: 11,
            ),
          ),
        ),
        if (itemsCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary
                  .withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: AppRadii.badgeRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.shoppingBag,
                  size: 13,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 5),
                Text(
                  'В акте: $itemsCount поз.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTabPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.pureWhite)
              : AppColors.transparent,
          borderRadius: AppRadii.badgeRadius,
          boxShadow: isSelected ? AppShadows.light : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.darkText : AppColors.lightText)
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
