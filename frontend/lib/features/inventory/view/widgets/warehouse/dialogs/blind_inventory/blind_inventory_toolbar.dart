// ==============================================================================
// 1. ИМПОРТЫ
// ==============================================================================
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_search_field.dart';

// ==============================================================================
// 2. ТУЛБАР ФИЛЬТРАЦИИ И ПОИСКА ИНВЕНТАРИЗАЦИИ
// ==============================================================================
/// [ИНВАРИАНТ] Панель инструментов инвентаризации с поиском, фильтром остатков и переключателем.
class BlindInventoryToolbar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final bool onlyUnfilled;
  final ValueChanged<bool> onOnlyUnfilledChanged;
  final bool isAllExpanded;
  final VoidCallback onToggleExpandAll;

  const BlindInventoryToolbar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onlyUnfilled,
    required this.onOnlyUnfilledChanged,
    required this.isAllExpanded,
    required this.onToggleExpandAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: AppSearchField(
            size: AppSearchFieldSize.md,
            hintText: 'Поиск номенклатуры для пересчета...',
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => onOnlyUnfilledChanged(!onlyUnfilled),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: onlyUnfilled
                  ? AppColors.warning.withValues(alpha: isDark ? 0.20 : 0.12)
                  : (isDark ? AppColors.darkCard : AppColors.lightBg),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: onlyUnfilled
                    ? AppColors.warning.withValues(alpha: 0.6)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  onlyUnfilled
                      ? PhosphorIconsRegular.checkSquare
                      : PhosphorIconsRegular.square,
                  size: 15,
                  color: onlyUnfilled
                      ? AppColors.warning
                      : (isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext),
                ),
                const SizedBox(width: 6),
                Text(
                  'Незаполненные',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight:
                        onlyUnfilled ? FontWeight.bold : FontWeight.w500,
                    color: onlyUnfilled
                        ? AppColors.warning
                        : (isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onToggleExpandAll,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAllExpanded
                      ? PhosphorIconsRegular.arrowsInSimple
                      : PhosphorIconsRegular.arrowsOutSimple,
                  size: 15,
                  color:
                      isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
                const SizedBox(width: 5),
                Text(
                  isAllExpanded ? 'Свернуть' : 'Развернуть',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
