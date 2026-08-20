import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import '../../services/pos_outbox_service.dart';
import '../../services/lan/local_pos_server.dart';
import 'dialogs/sync_outbox_dialog.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: PosOutboxService.listenable(),
      builder: (context, box, _) {
        final pendingCount = box.length;
        final hasPending = pendingCount > 0;
        final isLanActive = LocalPosServer.isRunning;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const SyncOutboxDialog(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasPending
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasPending
                    ? AppColors.warning.withValues(alpha: 0.4)
                    : AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPending
                      ? PhosphorIconsRegular.cloudSlash
                      : PhosphorIconsRegular.cloudCheck,
                  size: 16,
                  color: hasPending ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  hasPending ? 'В памяти: $pendingCount' : 'В сети',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasPending ? AppColors.warning : AppColors.success,
                  ),
                ),
                if (isLanActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    PhosphorIconsRegular.wifiHigh,
                    size: 14,
                    color: AppColors.brandPrimary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
