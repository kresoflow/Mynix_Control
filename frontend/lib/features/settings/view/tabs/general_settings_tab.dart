// ==============================================================================
// МОДУЛЬ: Настройки / Вкладка основных настроек заведения (GeneralSettingsTab)
// ДОМЕН: lib/features/settings/view/tabs/general_settings_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:kreso_frontend/features/settings/view/widgets/settings_ui_components.dart';
import 'package:kreso_frontend/features/settings/view/widgets/theme_appearance_settings_card.dart';

// ─── 1. Главная вкладка базовых параметров заведения ─────────────────────────

/// [UI-KIT] Вкладка параметров заведения, внешнего вида, региональных настроек.
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
              subtitle: 'Конфигурация бизнес-функций, интерфейса и параметров заведения',
            ),
            const SizedBox(height: 24),

            // ── 1. Функции заведения ─────────────────────────────────────────
            SettingsSectionHeader(
              title: 'Функции заведения',
              isDark: isDark,
              subtitle: 'Отображение заказов, списание и каталоги',
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
                SettingsDivider(isDark: isDark),
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
            const SizedBox(height: 32),

            // ── 2. Внешний вид ───────────────────────────────────────────────
            SettingsSectionHeader(
              title: 'Внешний вид',
              isDark: isDark,
              subtitle: 'Тема интерфейса и палитра бренда Kreso Flow',
            ),
            const SizedBox(height: 12),
            ThemeAppearanceSettingsCard(isDark: isDark),
            const SizedBox(height: 32),

            // ── 3. Региональные настройки ────────────────────────────────────
            SettingsSectionHeader(
              title: 'Региональные настройки',
              isDark: isDark,
              subtitle: 'Валюта расчетов и системный часовой пояс',
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
                    size: AppSegmentedSize.sm,
                    onValueChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateCurrency(val));
                    },
                    items: const [
                      AppSegmentedItem(value: '₽', label: '₽ Рубль'),
                      AppSegmentedItem(value: '₸', label: '₸ Тенге'),
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

            // ── 4. Системные настройки ───────────────────────────────────────
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
