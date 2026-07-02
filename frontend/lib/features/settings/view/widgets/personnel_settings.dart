import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'settings_components.dart';

class PersonnelSettings extends StatelessWidget {
  final bool isDark;
  const PersonnelSettings({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildSettingsHeader('Управление персоналом', isDark),
            ButtonStub(isDark: isDark, label: '+ Добавить сотрудника', isPrimary: true),
          ],
        ),
        const SizedBox(height: 32),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Иван Иванов (Администратор)',
              subtitle: 'Полный доступ • PIN: ****',
              trailing: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
            ),
            SettingsDivider(isDark: isDark),
            SettingsRow(
              isDark: isDark,
              title: 'Анна Смирнова (Кассир)',
              subtitle: 'Касса, Возвраты • PIN: ****',
              trailing: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.brandPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
