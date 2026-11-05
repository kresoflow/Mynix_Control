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
// 2. РЕЖИМЫ ОТОБРАЖЕНИЯ ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Режимы отображения диалога инвентаризации склада.
enum BlindInventoryViewMode {
  /// По строкам (быстрый поиск и табличный ввод)
  items,

  /// По категориям (аккордеоны цехов и складских зон)
  categories,
}

// ==============================================================================
// 3. ТУЛБАР ПЕРЕКЛЮЧЕНИЯ РЕЖИМОВ
// ==============================================================================
/// [ИНВАРИАНТ] Переключатель между строчным и категорийным режимом ревизии.
class BlindInventoryTabsBar extends StatelessWidget {
  final BlindInventoryViewMode viewMode;
  final ValueChanged<BlindInventoryViewMode> onViewModeChanged;
  final int filledCount;

  const BlindInventoryTabsBar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.filledCount,
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
                isSelected: viewMode == BlindInventoryViewMode.items,
                onTap: () => onViewModeChanged(BlindInventoryViewMode.items),
                isDark: isDark,
              ),
              _buildTabPill(
                label: 'По категориям',
                icon: PhosphorIconsRegular.squaresFour,
                isSelected: viewMode == BlindInventoryViewMode.categories,
                onTap: () => onViewModeChanged(BlindInventoryViewMode.categories),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            viewMode == BlindInventoryViewMode.categories
                ? 'Каталог цехов: сплошной пересчет по группам номенклатуры'
                : 'Построчный ввод: быстрый поиск и ввод фактического остатка',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              fontSize: 11,
            ),
          ),
        ),
        if (filledCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: AppRadii.badgeRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.clipboardText,
                  size: 13,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 5),
                Text(
                  '$filledCount',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? AppShadows.tabGlow(AppColors.brandPrimary) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.pureWhite
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.pureWhite
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
