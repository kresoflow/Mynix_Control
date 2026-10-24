import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'widgets/showcase/showcase_control_bar.dart';
import 'widgets/showcase/showcase_button_section.dart';
import 'widgets/showcase/showcase_menu_button_section.dart';
import 'widgets/showcase/showcase_badge_section.dart';
import 'widgets/showcase/showcase_nav_tile_section.dart';
import 'widgets/showcase/showcase_segmented_section.dart';
import 'widgets/showcase/showcase_filter_chip_section.dart';
import 'widgets/showcase/showcase_dialog_section.dart';
import 'widgets/showcase/showcase_motion_section.dart';
import 'widgets/showcase/showcase_sprint2_section.dart';
import 'widgets/showcase/showcase_sprint3_section.dart';
import 'widgets/showcase/showcase_forms_section.dart';

class UiKitShowcaseScreen extends StatefulWidget {
  const UiKitShowcaseScreen({super.key});

  @override
  State<UiKitShowcaseScreen> createState() => _UiKitShowcaseScreenState();
}

class _UiKitShowcaseScreenState extends State<UiKitShowcaseScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        cacheExtent: 400,
        itemCount: 13,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              );
            case 1:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseControlBar(onMotionChanged: () => setState(() {})),
                  const SizedBox(height: 24),
                ],
              );
            case 2:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseButtonSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 3:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseMenuButtonSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 4:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseBadgeSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 5:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseNavTileSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 6:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseSegmentedSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 7:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseFilterChipSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 8:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseDialogSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 9:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseMotionSection(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 10:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseSprint2Section(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 11:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShowcaseSprint3Section(isDark: isDark),
                  const SizedBox(height: 20),
                ],
              );
            case 12:
              return const ShowcaseFormsSection();
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
