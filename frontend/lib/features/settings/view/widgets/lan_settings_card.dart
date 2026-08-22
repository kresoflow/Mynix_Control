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
        return Column(
          children: [
            // 1. LAN Mesh Card
            Container(
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
                        child: Icon(
                          data.isLanEnabled ? PhosphorIconsRegular.wifiHigh : PhosphorIconsRegular.wifiSlash,
                          size: 20,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Локальная сеть (LAN Hub)', style: AppTextStyles.h3.copyWith(fontSize: 15)),
                            Text('Связь кассы и официантов по Wi-Fi без интернета', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Switch(
                        value: data.isLanEnabled,
                        activeThumbColor: AppColors.brandPrimary,
                        onChanged: (val) => LanSettingsService.setLanEnabled(val),
                      ),
                    ],
                  ),

                  if (data.isLanEnabled) ...[
                    const SizedBox(height: 16),
                    Text('Роль этого устройства:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRoleChoice('master', 'Касса-Сервер (Master)', PhosphorIconsRegular.desktop, data.role == 'master'),
                        _buildRoleChoice('client', 'Официант (Client)', PhosphorIconsRegular.deviceMobile, data.role == 'client'),
                        _buildRoleChoice('standalone', 'Автономный (Standalone)', PhosphorIconsRegular.lightning, data.role == 'standalone'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Master section
                    if (data.isMaster) ...[
                      if (kIsWeb) ...[
                        _buildBrowserNotice(),
                      ] else ...[
                        _buildLocalServerSection(data),
                      ],
                    ],

                    // Client section
                    if (data.isClient) ...[
                      LanClientSettingsSection(isDark: isDark),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Emergency Local DB (Offline Storage) Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(PhosphorIconsRegular.hardDrives, size: 20, color: AppColors.brandPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Аварийная локальная БД (Офлайн-чеки)', style: AppTextStyles.h3.copyWith(fontSize: 15)),
                        Text(
                          data.isOfflineStorageEnabled
                              ? 'Чеки сохраняются в память устройства при обрыве интернета'
                              : 'Строгий онлайн: создание чеков блокируется при отсутствии сети',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: data.isOfflineStorageEnabled,
                    activeThumbColor: AppColors.brandPrimary,
                    onChanged: (val) => LanSettingsService.setOfflineStorageEnabled(val),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleChoice(String roleValue, String label, IconData icon, bool isSelected) {
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? AppColors.brandPrimary : null),
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

  Widget _buildBrowserNotice() {
    return Container(
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
    );
  }

  Widget _buildLocalServerSection(LanSettingsData data) {
    return ValueListenableBuilder<bool>(
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
    );
  }
}
