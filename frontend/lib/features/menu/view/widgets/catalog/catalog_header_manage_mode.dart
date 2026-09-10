import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'catalog_enums.dart';

class CatalogHeaderManageMode extends StatelessWidget {
  final CategoryManageMode manageMode;
  final bool isMobile;
  final int selectedCount;
  final bool isAllSelected;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAllToggle;
  final VoidCallback onDeleteSelected;
  final VoidCallback? onToggleVisibilitySelected;

  const CatalogHeaderManageMode({
    super.key,
    required this.manageMode,
    required this.isMobile,
    required this.selectedCount,
    required this.isAllSelected,
    required this.onClearSelection,
    required this.onSelectAllToggle,
    required this.onDeleteSelected,
    this.onToggleVisibilitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (manageMode == CategoryManageMode.delete) {
      if (isMobile) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildSelectedBadge(isDark, isMobile: true),
                const Spacer(),
                AppGhostButton(
                  label: 'Отмена',
                  icon: PhosphorIconsRegular.x,
                  height: 32,
                  size: AppButtonSize.sm,
                  onPressed: onClearSelection,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: isAllSelected ? 'Снять' : 'Все',
                    icon: isAllSelected ? PhosphorIconsRegular.square : PhosphorIconsRegular.checkSquareOffset,
                    height: 32,
                    size: AppButtonSize.sm,
                    onPressed: onSelectAllToggle,
                  ),
                ),
                if (onToggleVisibilitySelected != null) ...[
                  const SizedBox(width: 6),
                  AppSecondaryButton(
                    label: '',
                    icon: PhosphorIconsRegular.eyeSlash,
                    tooltip: 'Скрыть / Показать',
                    height: 32,
                    width: 32,
                    size: AppButtonSize.sm,
                    onPressed: selectedCount > 0 ? onToggleVisibilitySelected : null,
                  ),
                ],
                const SizedBox(width: 6),
                Expanded(
                  child: AppDangerButton(
                    label: 'Удалить ($selectedCount)',
                    icon: PhosphorIconsRegular.trash,
                    height: 32,
                    size: AppButtonSize.sm,
                    onPressed: selectedCount > 0 ? onDeleteSelected : null,
                  ),
                ),
              ],
            ),
          ],
        );
      }

      return Row(
        children: [
          _buildSelectedBadge(isDark, isMobile: false),
          const SizedBox(width: 12),
          AppSecondaryButton(
            label: isAllSelected ? 'Снять выделение' : 'Выбрать все',
            icon: isAllSelected ? PhosphorIconsRegular.square : PhosphorIconsRegular.checkSquareOffset,
            height: 38,
            size: AppButtonSize.md,
            onPressed: onSelectAllToggle,
          ),
          const Spacer(),
          if (onToggleVisibilitySelected != null) ...[
            AppSecondaryButton(
              label: 'Скрыть / Показать',
              icon: PhosphorIconsRegular.eyeSlash,
              height: 38,
              size: AppButtonSize.md,
              onPressed: selectedCount > 0 ? onToggleVisibilitySelected : null,
            ),
            const SizedBox(width: 8),
          ],
          AppDangerButton(
            label: 'Удалить выбранные ($selectedCount)',
            icon: PhosphorIconsRegular.trash,
            height: 38,
            size: AppButtonSize.md,
            onPressed: selectedCount > 0 ? onDeleteSelected : null,
          ),
          const SizedBox(width: 8),
          AppGhostButton(
            label: 'Отмена',
            icon: PhosphorIconsRegular.x,
            height: 38,
            size: AppButtonSize.md,
            onPressed: onClearSelection,
          ),
        ],
      );
    }

    // Visibility mode
    return Row(
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.eye, size: 16, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text(
                'Режим настройки видимости',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Spacer(),
        AppGhostButton(
          label: 'Отмена',
          icon: PhosphorIconsRegular.x,
          height: 38,
          size: AppButtonSize.md,
          onPressed: onClearSelection,
        ),
      ],
    );
  }

  Widget _buildSelectedBadge(bool isDark, {required bool isMobile}) {
    final hasSelection = selectedCount > 0;
    final IconData badgeIcon = selectedCount == 0
        ? PhosphorIconsRegular.square
        : (isAllSelected ? PhosphorIconsRegular.checkSquare : PhosphorIconsRegular.minusSquare);

    final Color badgeColor = hasSelection
        ? AppColors.danger
        : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext);

    return Container(
      height: isMobile ? 32 : 38,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: hasSelection
            ? AppColors.danger.withValues(alpha: isDark ? 0.2 : 0.1)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hasSelection
              ? AppColors.danger.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: isMobile ? 14 : 16,
            color: badgeColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Выбрано: $selectedCount',
            style: (isMobile ? AppTextStyles.caption : AppTextStyles.bodyMedium).copyWith(
              fontWeight: FontWeight.w600,
              color: hasSelection ? badgeColor : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
        ],
      ),
    );
  }
}
