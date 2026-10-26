// ==============================================================================
// Title: SyncStatusBadge (sync_status_badge.dart)
// Path: frontend/lib/features/pos/view/widgets/sync_status_badge.dart
// Description: Индикатор сетевого статуса и очереди синхронизации офлайн-чеков.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import '../../services/pos_outbox_service.dart';
import '../../services/pos_sync_service.dart';
import 'dialogs/sync_outbox_dialog.dart';

// ─── 1. Виджет сетевого индикатора кассы ─────────────────────────────────────

/// [UI-KIT] [ИНВАРИАНТ] Статус синхронизации данных кассы:
/// - Зеленая точка: онлайн, очередь пуста (все данные сохранены на сервере).
/// - Желтый бейдж: офлайн, N чеков ожидают восстановления связи (предупреждение).
/// - Красный бейдж: сбой отправки / ошибка сети (требуется внимание кассира).
class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key});

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 1.0,
    );
    _pulseAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _updatePulse(bool shouldPulse) {
    if (shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    PosSyncService? syncService;
    try {
      syncService = context.read<PosSyncService>();
    } catch (_) {}

    return ValueListenableBuilder<Box>(
      valueListenable: PosOutboxService.listenable(),
      builder: (context, box, _) {
        final pendingCount = box.length;
        final hasPending = pendingCount > 0;

        // Если сервис доступен — считываем ошибки и статус синхронизации
        return ValueListenableBuilder<bool>(
          valueListenable: syncService?.isSyncing ?? ValueNotifier(false),
          builder: (context, isSyncing, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: syncService?.lastSyncError ?? ValueNotifier(null),
              builder: (context, lastError, _) {
                final hasError = lastError != null && hasPending;

                Color statusColor;
                Color bgColor;
                Color borderColor;
                IconData icon;
                String tooltipMsg;

                if (hasError) {
                  statusColor = AppColors.danger;
                  bgColor = AppColors.danger.withValues(alpha: 0.16);
                  borderColor = AppColors.danger.withValues(alpha: 0.6);
                  icon = PhosphorIconsBold.cloudSlash;
                  tooltipMsg = 'Ошибка отправки чеков! Нажмите для ручной синхронизации';
                } else if (isSyncing) {
                  statusColor = AppColors.warning;
                  bgColor = AppColors.warning.withValues(alpha: 0.16);
                  borderColor = AppColors.warning.withValues(alpha: 0.5);
                  icon = PhosphorIconsBold.arrowsClockwise;
                  tooltipMsg = 'Синхронизация чеков ($pendingCount)...';
                } else if (hasPending) {
                  statusColor = AppColors.warning;
                  bgColor = AppColors.warning.withValues(alpha: 0.16);
                  borderColor = AppColors.warning.withValues(alpha: 0.5);
                  icon = PhosphorIconsBold.cloudArrowUp;
                  tooltipMsg = 'Офлайн-режим! В очереди $pendingCount чеков. Нажмите для отправки';
                } else {
                  statusColor = AppColors.success;
                  bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
                  borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
                  icon = PhosphorIconsRegular.cloudCheck;
                  tooltipMsg = 'Касса в сети. Все данные синхронизированы';
                }

                Widget badgeContent = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Лаконичная светящаяся точка статуса сети
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(icon, size: 16, color: statusColor),
                    if (hasPending) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$pendingCount',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                );

                final shouldPulse = hasPending && !hasError && !isSyncing;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _updatePulse(shouldPulse);
                });

                if (shouldPulse) {
                  badgeContent = FadeTransition(
                    opacity: _pulseAnimation,
                    child: badgeContent,
                  );
                }

                return Tooltip(
                  message: tooltipMsg,
                  child: InkWell(
                    borderRadius: AppRadii.radiusMd,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SyncOutboxDialog(),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: AppRadii.radiusMd,
                        border: Border.all(color: borderColor, width: 1.1),
                      ),
                      child: badgeContent,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
