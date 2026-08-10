import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_ui_components.dart';

class TaxSettingsTab extends StatelessWidget {
  final bool isDark;
  const TaxSettingsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        buildSettingsHeader('Налоги и сборы', isDark),
        const SizedBox(height: 32),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'НДС по умолчанию',
              subtitle: 'Применяется ко всем новым товарам',
              trailing: DropdownStub(isDark: isDark, value: 'Без НДС'),
            ),
            SettingsDivider(isDark: isDark),
            SettingsRow(
              isDark: isDark,
              title: 'Включать налоги в цену',
              subtitle: 'Цены в каталоге отображаются с учетом налога',
              trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.brandPrimary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Сервисный сбор (Чаевые)',
              subtitle: 'Автоматически добавляется к заказу',
              trailing: DropdownStub(isDark: isDark, value: '10%'),
            ),
          ],
        ),
      ],
    );
  }
}
