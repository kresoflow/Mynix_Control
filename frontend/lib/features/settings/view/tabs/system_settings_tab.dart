import 'package:flutter/material.dart';
import 'package:mynix_frontend/features/settings/view/widgets/settings_ui_components.dart';

class SystemSettingsTab extends StatelessWidget {
  final bool isDark;
  const SystemSettingsTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      children: [
        buildSettingsHeader('О системе', isDark),
        const SizedBox(height: 32),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Версия Kreso Flow',
              subtitle: 'v1.0.0 (Сборка 42) — Последняя версия',
              trailing: ButtonStub(isDark: isDark, label: 'Проверить обновления', isPrimary: false),
            ),
            SettingsDivider(isDark: isDark),
            SettingsRow(
              isDark: isDark,
              title: 'Статус локальной базы (Hive)',
              subtitle: 'Синхронизировано (Размер: 2.4 МБ)',
              trailing: ButtonStub(isDark: isDark, label: 'Сбросить кэш', isPrimary: false),
            ),
          ],
        ),
      ],
    );
  }
}
