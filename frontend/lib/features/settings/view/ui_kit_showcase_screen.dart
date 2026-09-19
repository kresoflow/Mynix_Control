import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'widgets/showcase/showcase_button_section.dart';
import 'widgets/showcase/showcase_menu_button_section.dart';
import 'widgets/showcase/showcase_badge_section.dart';
import 'widgets/showcase/showcase_nav_tile_section.dart';
import 'widgets/showcase/showcase_segmented_section.dart';
import 'widgets/showcase/showcase_filter_chip_section.dart';
import 'widgets/showcase/showcase_dialog_section.dart';

class UiKitShowcaseScreen extends StatelessWidget {
  const UiKitShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            AppPageHeader(
              title: 'Kreso UI Kit & Design System Gallery',
              subtitle: 'Живая витрина стандартизированных компонентов, размеров и токенов',
              kpiChips: const [
                AppKpiChip(icon: PhosphorIconsRegular.cube, label: '5 Размеров кнопок'),
                AppKpiChip(icon: PhosphorIconsRegular.slidersHorizontal, label: '4 Категории навигации'),
                AppKpiChip(icon: PhosphorIconsRegular.checkCircle, label: 'Zero Hardcode', isHighlighted: true),
              ],
              actions: [
                AppMenuButton(
                  label: 'Действия UI Kit',
                  icon: PhosphorIconsRegular.dotsThreeOutline,
                  size: AppButtonSize.md,
                  items: const [
                    AppMenuItem(id: 'refresh', label: 'Перезагрузить токены', icon: PhosphorIconsRegular.arrowsClockwise),
                    AppMenuItem(id: 'copy_spec', label: 'Скопировать DESIGN.md', icon: PhosphorIconsRegular.copy),
                    AppMenuDivider(),
                    AppMenuItem(id: 'reset', label: 'Сброс', icon: PhosphorIconsRegular.trash, isDestructive: true),
                  ],
                  onSelected: (val) => AppToast.showInfo(context, 'Действие: $val'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Buttons Matrix
            ShowcaseButtonSection(isDark: isDark),
            const SizedBox(height: 20),

            // 2. Dropdown Actions (AppMenuButton)
            ShowcaseMenuButtonSection(isDark: isDark),
            const SizedBox(height: 20),

            // 3. Status Badges & Indicators
            ShowcaseBadgeSection(isDark: isDark),
            const SizedBox(height: 20),

            // 4. Vertical Lists & Trees (AppNavTile)
            ShowcaseNavTileSection(isDark: isDark),
            const SizedBox(height: 20),

            // 5. Horizontal Segmented Controls (AppSegmentedControl)
            ShowcaseSegmentedSection(isDark: isDark),
            const SizedBox(height: 20),

            // 6. Data Filters (AppFilterChip & AppFilterBar)
            ShowcaseFilterChipSection(isDark: isDark),
            const SizedBox(height: 20),

            // 7. Dialogs, Search & Toasts
            ShowcaseDialogSection(isDark: isDark),
          ],
        ),
      ),
    );
  }
}
