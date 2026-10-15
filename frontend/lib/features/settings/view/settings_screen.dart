// ==============================================================================
// МОДУЛЬ: Настройки / Главный экран настроек системы (SettingsScreen)
// ДОМЕН: lib/features/settings/view/settings_screen.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/settings/view/tabs/general_settings_tab.dart';
import 'package:kreso_frontend/features/settings/view/tabs/personnel_settings_tab.dart';
import 'package:kreso_frontend/features/settings/view/tabs/system_settings_tab.dart';
import 'package:kreso_frontend/features/settings/view/ui_kit_showcase_screen.dart';

class _SettingsCategory {
  final IconData icon;
  final String title;

  const _SettingsCategory(this.icon, this.title);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<_SettingsCategory> _categories = const [
    _SettingsCategory(PhosphorIconsRegular.slidersHorizontal, 'Основные'),
    _SettingsCategory(PhosphorIconsRegular.users, 'Персонал'),
    _SettingsCategory(PhosphorIconsRegular.hardDrives, 'Система'),
    _SettingsCategory(PhosphorIconsRegular.paintBrushBroad, 'UI Kit & Дизайн'),
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: SingleChildScrollView(
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

                          return AppNavTile(
                            title: category.title,
                            icon: category.icon,
                            isSelected: isSelected,
                            size: AppNavTileSize.lg,
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
    if (_selectedIndex == 3) {
      return const UiKitShowcaseScreen();
    }

    final Widget content;
    switch (_selectedIndex) {
      case 0:
        content = GeneralSettingsTab(isDark: isDark);
        break;
      case 1:
        content = PersonnelSettingsTab(isDark: isDark);
        break;
      case 2:
        content = SystemSettingsTab(isDark: isDark);
        break;
      default:
        content = const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: content,
      ),
    );
  }
}
