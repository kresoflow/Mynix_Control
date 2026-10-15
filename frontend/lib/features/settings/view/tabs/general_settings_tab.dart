// ==============================================================================
// МОДУЛЬ: Настройки / Вкладка основных настроек заведения (GeneralSettingsTab)
// ДОМЕН: lib/features/settings/view/tabs/general_settings_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/features/settings/view/widgets/settings_ui_components.dart';

// ─── 1. Главная вкладка базовых параметров заведения ─────────────────────────

/// [UI-KIT] Вкладка параметров заведения, региональных настроек и уведомлений.
class GeneralSettingsTab extends StatelessWidget {
  final bool isDark;

  const GeneralSettingsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final isMobile = MediaQuery.of(context).size.width < 700;

        return ListView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          children: [
            // Заголовок страницы
            const AppPageHeader(
              title: 'Основные настройки',
              subtitle: 'Конфигурация бизнес-функций, параметров учета и заведения',
            ),
            const SizedBox(height: 24),

            // ── 1. Функции заведения ─────────────────────────────────────────
            SettingsSectionHeader(
              title: 'Функции заведения',
              isDark: isDark,
              subtitle: 'Отображение заказов и автоматическое списание сырья',
            ),
            const SizedBox(height: 12),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Показывать вкладку Заказы',
                  subtitle: 'Отображать вкладку с активными заказами на экране кассы',
                  trailing: AppSwitch(
                    value: state.useOrders,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(
                            UpdateStoreSettings(useOrders: val),
                          );
                    },
                  ),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  title: 'Списание ингредиентов',
                  subtitle: 'Минусовать сырье по тех. картам при продаже',
                  trailing: AppSwitch(
                    value: state.enableInventory,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(
                            UpdateStoreSettings(enableInventory: val),
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── 2. Региональные настройки ────────────────────────────────────
            SettingsSectionHeader(
              title: 'Региональные настройки',
              isDark: isDark,
              subtitle: 'Валюта расчетов и системный часовой пояс торговой точки',
            ),
            const SizedBox(height: 12),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Валюта по умолчанию',
                  subtitle: 'Отображается в кассе, чеках и аналитике',
                  trailing: AppSegmentedControl<String>(
                    selectedValue: state.currency,
                    size: AppSegmentedSize.md,
                    onValueChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateCurrency(val));
                    },
                    items: const [
                      AppSegmentedItem(value: '₽', label: '₽ Рубль'),
                      AppSegmentedItem(value: r'$', label: r'$ Доллар'),
                      AppSegmentedItem(value: 'с', label: 'с TJS'),
                    ],
                  ),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  title: 'Часовой пояс',
                  subtitle: 'Определяет время чеков и смен',
                  trailing: SettingsDropdown<String>(
                    isDark: isDark,
                    value: state.timezone,
                    items: const [
                      'GMT+3 (Москва)',
                      'GMT+5 (Ташкент/Душанбе)',
                      'GMT+6 (Бишкек/Алматы)',
                    ],
                    itemLabel: (item) => item,
                    onSelected: (tz) {
                      context.read<SettingsBloc>().add(
                            UpdateStoreSettings(timezone: tz),
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── 3. Системные уведомления ─────────────────────────────────────
            SettingsSectionHeader(
              title: 'Системные настройки',
              isDark: isDark,
              subtitle: 'Звуковые сигналы и обратная связь',
            ),
            const SizedBox(height: 12),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  title: 'Звуковые уведомления',
                  subtitle: 'Звуки при успешной оплате или ошибках',
                  trailing: AppSwitch(
                    value: state.soundEnabled,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(
                            UpdateStoreSettings(soundEnabled: val),
                          );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
