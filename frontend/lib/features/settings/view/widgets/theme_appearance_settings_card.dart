import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'settings_ui_components.dart';

class ThemeAppearanceSettingsCard extends StatelessWidget {
  final bool isDark;

  const ThemeAppearanceSettingsCard({super.key, required this.isDark});

  Widget _buildModeBtn(
    BuildContext context, {
    required bool isDark,
    required String label,
    required PhosphorIconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.brandPrimary
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.brandPrimary
                    : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteBtn(
    BuildContext context, {
    required bool isDark,
    required String label,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Режим отображения',
              subtitle: 'Переключение между светлым и тёмным интерфейсом',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModeBtn(
                    context,
                    isDark: isDark,
                    label: 'Светлый',
                    icon: PhosphorIconsRegular.sun,
                    isSelected: themeState.mode == ThemeMode.light,
                    onTap: () => context.read<ThemeBloc>().add(const SetThemeMode(ThemeMode.light)),
                  ),
                  _buildModeBtn(
                    context,
                    isDark: isDark,
                    label: 'Тёмный',
                    icon: PhosphorIconsRegular.moon,
                    isSelected: themeState.mode == ThemeMode.dark,
                    onTap: () => context.read<ThemeBloc>().add(const SetThemeMode(ThemeMode.dark)),
                  ),
                  _buildModeBtn(
                    context,
                    isDark: isDark,
                    label: 'Системный',
                    icon: PhosphorIconsRegular.desktop,
                    isSelected: themeState.mode == ThemeMode.system,
                    onTap: () => context.read<ThemeBloc>().add(const SetThemeMode(ThemeMode.system)),
                  ),
                ],
              ),
            ),
            SettingsDivider(isDark: isDark),
            SettingsRow(
              isDark: isDark,
              title: 'Цветовой стиль бренда',
              subtitle: 'Парная палитра с синхронным светлым и тёмным режимом',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaletteBtn(
                    context,
                    isDark: isDark,
                    label: 'Classic Ember (Янтарь)',
                    accentColor: const Color(0xFFE8A020),
                    isSelected: themeState.palette == ThemePalette.ember,
                    onTap: () => context.read<ThemeBloc>().add(const SetThemePalette(ThemePalette.ember)),
                  ),
                  _buildPaletteBtn(
                    context,
                    isDark: isDark,
                    label: 'Soft Cream (Крем / Эспрессо)',
                    accentColor: const Color(0xFFD97706),
                    isSelected: themeState.palette == ThemePalette.cream,
                    onTap: () => context.read<ThemeBloc>().add(const SetThemePalette(ThemePalette.cream)),
                  ),
                  _buildPaletteBtn(
                    context,
                    isDark: isDark,
                    label: 'Deep Ocean (Контраст / Океан)',
                    accentColor: const Color(0xFF00F0FF),
                    isSelected: themeState.palette == ThemePalette.ocean,
                    onTap: () => context.read<ThemeBloc>().add(const SetThemePalette(ThemePalette.ocean)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
