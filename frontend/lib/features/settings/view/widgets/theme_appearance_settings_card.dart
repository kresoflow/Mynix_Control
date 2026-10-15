// ==============================================================================
// МОДУЛЬ: Настройки / Карточка выбора темы и палитры бренда
// ДОМЕН: lib/features/settings/view/widgets/theme_appearance_settings_card.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/theme_bloc.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'settings_ui_components.dart';

// ─── 1. Карточка темы и палитры бренда на базе AppSegmentedControl ────────────

/// [UI-KIT] Настройка светлой/тёмной темы и акцентной палитры бренда Kreso Flow.
class ThemeAppearanceSettingsCard extends StatelessWidget {
  final bool isDark;

  const ThemeAppearanceSettingsCard({super.key, required this.isDark});

  static Widget _buildColorDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
              trailing: AppSegmentedControl<ThemeMode>(
                selectedValue: themeState.mode,
                size: AppSegmentedSize.md,
                onValueChanged: (mode) =>
                    context.read<ThemeBloc>().add(SetThemeMode(mode)),
                items: const [
                  AppSegmentedItem(
                    value: ThemeMode.light,
                    label: 'Светлый',
                    icon: PhosphorIconsRegular.sun,
                  ),
                  AppSegmentedItem(
                    value: ThemeMode.dark,
                    label: 'Тёмный',
                    icon: PhosphorIconsRegular.moon,
                  ),
                  AppSegmentedItem(
                    value: ThemeMode.system,
                    label: 'Системный',
                    icon: PhosphorIconsRegular.desktop,
                  ),
                ],
              ),
            ),
            SettingsDivider(isDark: isDark),
            SettingsRow(
              isDark: isDark,
              title: 'Цветовой стиль бренда',
              subtitle: 'Парная палитра с синхронным светлым и тёмным режимом',
              trailing: AppSegmentedControl<ThemePalette>(
                selectedValue: themeState.palette,
                size: AppSegmentedSize.md,
                onValueChanged: (palette) =>
                    context.read<ThemeBloc>().add(SetThemePalette(palette)),
                items: [
                  AppSegmentedItem(
                    value: ThemePalette.ember,
                    label: 'Ember',
                    leading: _buildColorDot(const Color(0xFFE8A020)),
                  ),
                  AppSegmentedItem(
                    value: ThemePalette.cream,
                    label: 'Cream',
                    leading: _buildColorDot(const Color(0xFFD97706)),
                  ),
                  AppSegmentedItem(
                    value: ThemePalette.ocean,
                    label: 'Ocean',
                    leading: _buildColorDot(const Color(0xFF00F0FF)),
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
