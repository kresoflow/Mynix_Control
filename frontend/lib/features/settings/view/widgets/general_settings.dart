import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'settings_components.dart';

class GeneralSettings extends StatelessWidget {
  final bool isDark;
  const GeneralSettings({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(40),
          children: [
            buildSettingsHeader('Внешний вид', isDark),
            const SizedBox(height: 32),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Цветовая схема (Тема)',
                  subtitle: 'Выбор светлой или темной темы',
                  trailing: BlocBuilder<ThemeBloc, ThemeMode>(
                    builder: (context, themeMode) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлая (Basic)',
                            isSelected: themeMode == ThemeMode.light && state.themeVariant == 'basic',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('basic'));
                              if (themeMode != ThemeMode.light) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлая (Cream)',
                            isSelected: themeMode == ThemeMode.light && state.themeVariant == 'soft_cream',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('soft_cream'));
                              if (themeMode != ThemeMode.light) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Светлая (Contrast)',
                            isSelected: themeMode == ThemeMode.light && state.themeVariant == 'high_contrast_light',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('high_contrast_light'));
                              if (themeMode != ThemeMode.light) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Темная (Ember)',
                            isSelected: themeMode == ThemeMode.dark && state.themeVariant == 'basic',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('basic'));
                              if (themeMode != ThemeMode.dark) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                          _buildThemeVariantBtn(
                            context,
                            isDark: isDark,
                            label: 'Темная (Deep Ocean)',
                            isSelected: themeMode == ThemeMode.dark && state.themeVariant == 'deep_ocean',
                            onTap: () {
                              context.read<SettingsBloc>().add(const UpdateThemeVariant('deep_ocean'));
                              if (themeMode != ThemeMode.dark) {
                                context.read<ThemeBloc>().add(ThemeEvent.toggleTheme);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            buildSettingsHeader('Региональные настройки', isDark),
            const SizedBox(height: 32),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Валюта по умолчанию',
                  subtitle: 'Отображается в кассе, чеках и аналитике',
                  trailing: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCurrencyBtn(context, isDark, state, '₽', 'Рубль'),
                      _buildCurrencyBtn(context, isDark, state, '₸', 'Тенге'),
                      _buildCurrencyBtn(context, isDark, state, 'с', 'TJS'),
                    ],
                  ),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  title: 'Часовой пояс',
                  subtitle: 'Определяет время чеков и смен',
                  trailing: DropdownStub(isDark: isDark, value: 'GMT+3 (Москва)'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            buildSettingsHeader('Системные настройки', isDark),
            const SizedBox(height: 32),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Звуковые уведомления',
                  subtitle: 'Звуки при успешной оплате или ошибках',
                  trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.brandPrimary),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeVariantBtn(
    BuildContext context, {
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyBtn(BuildContext context, bool isDark, SettingsState state, String code, String name) {
    final isSelected = state.currency == code;
    return InkWell(
      onTap: () {
        context.read<SettingsBloc>().add(UpdateCurrency(code));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.15) : (isDark ? AppColors.darkBg : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkText : AppColors.lightText),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
