// ==============================================================================
// МОДУЛЬ: Настройки / Вкладка оформления и визуального стиля (AppearanceTab)
// ДОМЕН: lib/features/settings/view/tabs/appearance_settings_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:kreso_frontend/features/settings/view/widgets/settings_ui_components.dart';
import 'package:kreso_frontend/features/settings/view/widgets/theme_appearance_settings_card.dart';

// ─── 1. Вкладка визуального оформления приложения ─────────────────────────────

/// [UI-KIT] Вкладка настроек темы (светлая/тёмная), палитры бренда и цветных категорий.
class AppearanceSettingsTab extends StatelessWidget {
  final bool isDark;

  const AppearanceSettingsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      children: [
        // Заголовок страницы
        const AppPageHeader(
          title: 'Оформление',
          subtitle: 'Персонализация цветовой темы, палитры бренда и карточек меню',
        ),
        const SizedBox(height: 24),

        // ── 1. Тема и палитра бренда ─────────────────────────────────────────
        SettingsSectionHeader(
          title: 'Тема и стиль бренда',
          isDark: isDark,
          subtitle: 'Синхронный светлый и тёмный интерфейс с акцентными цветами',
        ),
        const SizedBox(height: 12),
        ThemeAppearanceSettingsCard(isDark: isDark),
        const SizedBox(height: 32),

        // ── 2. Цветовая дифференциация в меню ────────────────────────────────
        SettingsSectionHeader(
          title: 'Отображение в меню',
          isDark: isDark,
          subtitle: 'Визуальные акценты карточек блюд на экране кассира',
        ),
        const SizedBox(height: 12),
        SettingsCard(
          isDark: isDark,
          children: [
            BlocBuilder<PosSettingsCubit, PosSettingsState>(
              builder: (context, posState) {
                return SettingsRow(
                  isDark: isDark,
                  title: 'Цветные категории',
                  subtitle: 'Использовать цвета категорий из каталога для карточек меню',
                  trailing: AppSwitch(
                    value: posState.enableRainbowColors,
                    onChanged: (_) {
                      context.read<PosSettingsCubit>().toggleRainbowColors();
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
