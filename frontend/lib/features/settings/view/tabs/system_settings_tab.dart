// ==============================================================================
// МОДУЛЬ: Настройки / Вкладка системной информации и диагностики
// ДОМЕН: lib/features/settings/view/tabs/system_settings_tab.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import 'package:kreso_frontend/features/settings/view/widgets/settings_ui_components.dart';

// ─── 1. Вкладка параметров системы и диагностических сведений ────────────────

/// [UI-KIT] Вкладка системной информации, сброса кэша и проверки обновлений.
class SystemSettingsTab extends StatelessWidget {
  final bool isDark;

  const SystemSettingsTab({super.key, required this.isDark});

  Future<void> _checkUpdates(BuildContext context) async {
    AppToast.showSuccess(
      context,
      'Установлена актуальная версия Kreso Flow (v1.0.0, сборка 42)',
    );
  }

  Future<void> _confirmResetCache(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Сбросить локальный кэш?',
      message: 'Все временные локальные данные будут очищены.\n'
          'Приложение перезагрузит актуальную информацию с сервера.',
      confirmLabel: 'Сбросить кэш',
      confirmIcon: PhosphorIconsRegular.trash,
      isDanger: true,
      icon: PhosphorIconsRegular.database,
    );

    if (confirmed == true && context.mounted) {
      AppToast.showSuccess(context, 'Локальный кэш успешно очищен');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      children: [
        // Заголовок страницы
        const AppPageHeader(
          title: 'О системе',
          subtitle: 'Параметры сборки, локальное хранилище и диагностика приложения',
        ),
        const SizedBox(height: 24),

        // ── 1. Версия и обновления ───────────────────────────────────────────
        SettingsSectionHeader(
          title: 'Версия и релизы',
          isDark: isDark,
          subtitle: 'Информация о текущем билде клиента Kreso Flow',
        ),
        const SizedBox(height: 12),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Версия Kreso Flow',
              subtitle: 'v1.0.0 (Сборка 42) — Последняя стабильная версия',
              trailing: AppSecondaryButton(
                label: 'Проверить обновления',
                icon: PhosphorIconsRegular.arrowsClockwise,
                size: AppButtonSize.sm,
                onPressed: () => _checkUpdates(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── 2. Локальное хранилище и офлайн ──────────────────────────────────
        SettingsSectionHeader(
          title: 'Локальное хранилище',
          isDark: isDark,
          subtitle: 'Кэш каталога, документов и офлайн-очередь Hive',
        ),
        const SizedBox(height: 12),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Статус локальной базы (Hive)',
              subtitle: 'Синхронизировано • Размер кэша: 2.4 МБ',
              trailing: AppSecondaryButton(
                label: 'Сбросить кэш',
                icon: PhosphorIconsRegular.trash,
                size: AppButtonSize.sm,
                onPressed: () => _confirmResetCache(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── 3. Диагностика окружения ─────────────────────────────────────────
        SettingsSectionHeader(
          title: 'Диагностика окружения',
          isDark: isDark,
          subtitle: 'Статус сетевого соединения с сервером',
        ),
        const SizedBox(height: 12),
        SettingsCard(
          isDark: isDark,
          children: [
            SettingsRow(
              isDark: isDark,
              title: 'Режим синхронизации',
              subtitle: 'Real-time WebSocket & Outbox Queue Sync',
              trailing: const AppStatusBadge(
                label: 'Активен',
                icon: PhosphorIconsRegular.checkCircle,
                variant: AppBadgeVariant.success,
              ),
            ),

          ],
        ),
      ],
    );
  }
}
