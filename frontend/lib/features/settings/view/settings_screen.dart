import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_dialogs.dart';

import 'package:mynix_frontend/features/settings/view/tabs/general_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/hardware_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/personnel_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/tax_settings_tab.dart';
import 'package:mynix_frontend/features/settings/view/tabs/system_settings_tab.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<_SettingsCategory> _categories = [
    _SettingsCategory(PhosphorIconsRegular.slidersHorizontal, 'Основные'),
    _SettingsCategory(PhosphorIconsRegular.printer, 'Оборудование'),
    _SettingsCategory(PhosphorIconsRegular.users, 'Персонал'),
    _SettingsCategory(PhosphorIconsRegular.receipt, 'Налоги и сборы'),
    _SettingsCategory(PhosphorIconsRegular.hardDrives, 'Система'),
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
                          _buildProfileMenu(context, isDark),
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

                          return _CategoryTile(
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
        }
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

  Widget _buildProfileMenu(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
      tooltip: 'Профиль пользователя',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 8,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary.withOpacity(0.15),
          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.3)),
        ),
        child: Center(
          child: Icon(PhosphorIconsRegular.user, size: 24, color: AppColors.brandPrimary),
        ),
      ),
      onSelected: (value) {
        if (value == 'close_shift') {
          SettingsDialogs.showCloseShiftDialog(context);
        } else if (value == 'logout') {
          context.read<AuthBloc>().add(LoggedOut());
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Владелец платформы', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text('Полный доступ', style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'close_shift',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.lockKey, color: AppColors.danger, size: 20),
              const SizedBox(width: 12),
              Text('Закрыть смену', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.signOut, color: AppColors.darkSubtext, size: 20),
              const SizedBox(width: 12),
              Text('Выйти из аккаунта', style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCategory {
  final IconData icon;
  final String title;

  _SettingsCategory(this.icon, this.title);
}

class _CategoryTile extends StatelessWidget {
  final _SettingsCategory category;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(category.icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              category.title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.darkText : AppColors.lightText)
                    : color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
