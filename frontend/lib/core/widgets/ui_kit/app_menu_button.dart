import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_radii.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';

abstract class AppMenuEntryBase {
  const AppMenuEntryBase();
}

class AppMenuItem extends AppMenuEntryBase {
  final String id;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final String? shortcut;
  final bool isDestructive;

  const AppMenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.iconColor,
    this.shortcut,
    this.isDestructive = false,
  });
}

class AppMenuDivider extends AppMenuEntryBase {
  const AppMenuDivider();
}

/// Unified Dropdown Action Button for Mynix Control
class AppMenuButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final List<AppMenuEntryBase> items;
  final ValueChanged<String> onSelected;
  final String? tooltip;
  final bool isFullWidth;

  const AppMenuButton({
    super.key,
    required this.label,
    this.icon,
    this.size = AppButtonSize.md,
    this.variant = AppButtonVariant.primary,
    required this.items,
    required this.onSelected,
    this.tooltip,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      tooltip: tooltip ?? label,
      offset: const Offset(0, 42),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (ctx) {
        final List<PopupMenuEntry<String>> entries = [];

        for (final item in items) {
          if (item is AppMenuDivider) {
            entries.add(
              PopupMenuDivider(
                height: 1,
              ),
            );
          } else if (item is AppMenuItem) {
            final fg = item.isDestructive
                ? AppColors.danger
                : (isDark ? AppColors.darkText : AppColors.lightText);

            entries.add(
              PopupMenuItem<String>(
                value: item.id,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 16,
                        color: item.iconColor ?? (item.isDestructive ? AppColors.danger : AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: fg,
                          fontSize: 13,
                          fontWeight: item.isDestructive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.shortcut != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.6) : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.shortcut!,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
        }
        return entries;
      },
      child: IgnorePointer(
        child: AppButton(
          label: label,
          icon: icon,
          size: size,
          variant: variant,
          isFullWidth: isFullWidth,
          onPressed: () {},
        ),
      ),
    );
  }
}
