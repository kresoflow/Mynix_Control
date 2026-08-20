import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/pos/services/lan/local_pos_server.dart';
import '../../services/lan_settings_service.dart';
import 'lan_client_settings_section.dart';

class LanSettingsCard extends StatelessWidget {
  final bool isDark;

  const LanSettingsCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LanSettingsData>(
      valueListenable: LanSettingsService.settingsNotifier,
      builder: (context, data, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(PhosphorIconsRegular.wifiHigh, size: 20, color: AppColors.brandPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Локальная сеть & Кассовый сервер (LAN Hub)', style: AppTextStyles.h3.copyWith(fontSize: 15)),
                        Text('Прямая связь между кассой и официантами без интернета', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Role selector
              Text('Роль этого устройства:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildRoleChoice('master', '🖥️ Касса-Сервер (Master)', data.role == 'master'),
                  _buildRoleChoice('client', '📱 Официант (Client)', data.role == 'client'),
                  _buildRoleChoice('standalone', '⚡ Автономный (Standalone)', data.role == 'standalone'),
                ],
              ),
              const SizedBox(height: 16),

              // Master section
              if (data.isMaster) ...[
                if (kIsWeb) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(PhosphorIconsRegular.info, color: AppColors.brandPrimary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Режим Сервера в браузере', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                'Браузер (Web) работает в изолированной песочнице и не может напрямую слушать сетевой TCP-порт. Для работы в качестве сервера приема заказов запустите приложение на Windows (Desktop). В браузере используйте режим «Официант» или «Автономный».',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ValueListenableBuilder<bool>(
                    valueListenable: LocalPosServer.isRunningNotifier,
                    builder: (context, isRunning, _) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Локальный сервер приема заказов', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                Text(
                                  isRunning
                                      ? 'Адрес для официантов: http://${LocalPosServer.localIpAddress ?? "192.168.1.x"}:${data.port}'
                                      : 'Сервер отключен',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isRunning ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: data.isServerEnabled,
                              activeThumbColor: AppColors.brandPrimary,
                              onChanged: (val) => LanSettingsService.setServerEnabled(val),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],

              // Client section
              if (data.isClient) ...[
                LanClientSettingsSection(isDark: isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleChoice(String roleValue, String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => LanSettingsService.setRole(roleValue),
      selectedColor: AppColors.brandPrimary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.brandPrimary : null,
      ),
    );
  }
}
