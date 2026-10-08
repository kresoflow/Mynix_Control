import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';

import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/settings/view/tabs/general_settings_tab.dart';
import 'package:kreso_frontend/features/settings/view/tabs/personnel_settings_tab.dart';
import 'package:kreso_frontend/features/settings/view/tabs/system_settings_tab.dart';
import 'package:kreso_frontend/features/settings/view/ui_kit_showcase_screen.dart';
import 'package:kreso_frontend/features/settings/view/widgets/settings_category_tile.dart';
import 'package:kreso_frontend/features/settings/view/widgets/mobile_settings_user_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<SettingsCategory> _categories = const [
    SettingsCategory(PhosphorIconsRegular.slidersHorizontal, 'Основные'),
    SettingsCategory(PhosphorIconsRegular.users, 'Персонал'),
    SettingsCategory(PhosphorIconsRegular.hardDrives, 'Система'),
    SettingsCategory(PhosphorIconsRegular.paintBrushBroad, 'UI Kit & Дизайн'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 768) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      MobileSettingsUserHeader(isDark: isDark),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: AppSegmentedControl<int>(
                          selectedValue: _selectedIndex,
                          size: AppSegmentedSize.sm,
                          onValueChanged: (idx) => setState(() => _selectedIndex = idx),
                          items: List.generate(_categories.length, (index) {
                            final cat = _categories[index];
                            return AppSegmentedItem<int>(
                              value: index,
                              label: cat.title,
                              icon: cat.icon,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildCategoryContent(isDark),
                ),
              ],
            );
          }

          // Desktop/Tablet layout
          return Row(
            children: [
              // Left panel - category list
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Настройки',
                        style: AppTextStyles.h1.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = index == _selectedIndex;

                          return SettingsCategoryTile(
                            category: category,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Right panel - content of selected category
              Expanded(
                child: _buildCategoryContent(isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryContent(bool isDark) {
    switch (_selectedIndex) {
      case 0:
        return GeneralSettingsTab(isDark: isDark);
      case 1:
        return PersonnelSettingsTab(isDark: isDark);
      case 2:
        return SystemSettingsTab(isDark: isDark);
      case 3:
        return const UiKitShowcaseScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
