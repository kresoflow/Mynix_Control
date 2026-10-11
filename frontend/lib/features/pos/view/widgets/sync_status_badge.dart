// ==============================================================================
// МОДУЛЬ: POS / Индикатор сетевого статуса и очереди синхронизации (Calm Tech)
// ДОМЕН: lib/features/pos/view/widgets/sync_status_badge.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import '../../services/pos_outbox_service.dart';
import 'dialogs/sync_outbox_dialog.dart';

// ── Индикатор статуса синхронизации ──────────────────────────────────────────

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<Box>(
      valueListenable: PosOutboxService.listenable(),
      builder: (context, box, _) {
        final pendingCount = box.length;
        final hasPending = pendingCount > 0;
        final statusColor = hasPending ? AppColors.danger : AppColors.success;
        final bgColor = hasPending
            ? AppColors.danger.withValues(alpha: 0.16)
            : (isDark ? AppColors.darkCard : AppColors.lightCard);
        final borderColor = hasPending
            ? AppColors.danger.withValues(alpha: 0.5)
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

        final tooltipMsg = hasPending
            ? 'Офлайн-режим! В очереди $pendingCount чеков. Нажмите для синхронизации'
            : 'Касса в сети. Все данные синхронизированы';

        return Tooltip(
          message: tooltipMsg,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const SyncOutboxDialog(),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 38,
              padding: EdgeInsets.symmetric(horizontal: hasPending ? 10 : 9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasPending
                        ? PhosphorIconsBold.cloudSlash
                        : PhosphorIconsRegular.cloudCheck,
                    size: 18,
                    color: statusColor,
                  ),
                  if (hasPending) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$pendingCount',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
