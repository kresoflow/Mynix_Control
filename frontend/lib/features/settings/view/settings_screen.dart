import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

import 'package:mynix_frontend/features/settings/view/tabs/general_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/hardware_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/personnel_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/tax_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/system_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_category_tile.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_profile_menu.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<SettingsCategory> _categories = const [
    SettingsCategory(PhosphorIconsRegular.slidersHorizontal, 'Основные'),
    SettingsCategory(PhosphorIconsRegular.printer, 'Оборудование'),
    SettingsCategory(PhosphorIconsRegular.users, 'Персонал'),
    SettingsCategory(PhosphorIconsRegular.receipt, 'Налоги и сборы'),
    SettingsCategory(PhosphorIconsRegular.hardDrives, 'Система'),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Настройки', style: AppTextStyles.h1.copyWith(color: isDark ? AppColors.darkText : AppColors.lightText)),
                          SettingsProfileMenu(isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_categories.length, (index) {
                            final category = _categories[index];
                            final isSelected = index == _selectedIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(category.title),
                                avatar: Icon(category.icon, size: 18, color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedIndex = index);
                                  }
                                },
                                selectedColor: AppColors.brandPrimary,
                                backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                                labelStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                                ),
                              ),
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
        return HardwareSettingsTab(isDark: isDark);
      case 2:
        return PersonnelSettingsTab(isDark: isDark);
      case 3:
        return TaxSettingsTab(isDark: isDark);
      case 4:
        return SystemSettingsTab(isDark: isDark);
      default:
        return const SizedBox.shrink();
    }
  }
}
