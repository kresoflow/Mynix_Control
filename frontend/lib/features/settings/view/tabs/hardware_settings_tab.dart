import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_ui_components.dart';

class HardwareSettingsTab extends StatelessWidget {
  final bool isDark;
  const HardwareSettingsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        buildSettingsHeader('Оборудование', isDark),
        const SizedBox(height: 32),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Принтер чеков',
              subtitle: 'Не подключен',
              trailing: ButtonStub(isDark: isDark, label: 'Поиск устройств', isPrimary: true),
            ),
            SettingsDivider(isDark: isDark),
            SettingsRow(
              isDark: isDark,
              title: 'Шаблон чека',
              subtitle: 'Стандартный (Ширина 80мм)',
              trailing: ButtonStub(isDark: isDark, label: 'Настроить', isPrimary: false),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Сканер штрих-кодов',
              subtitle: 'Режим эмуляции клавиатуры',
              trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.brandPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
