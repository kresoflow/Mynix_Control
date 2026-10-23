// ==============================================================================
// МОДУЛЬ: POS / Диалог очереди офлайн-чеков и синхронизации
// ДОМЕН: lib/features/pos/view/widgets/dialogs/sync_outbox_dialog.dart
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';
import '../../../services/pos_outbox_service.dart';
import '../../../services/pos_sync_service.dart';
import 'sync_outbox_order_card.dart';

/// [UI-KIT] Диалог управления офлайн-чеками на базе AppCardDialog
class SyncOutboxDialog extends StatefulWidget {
  const SyncOutboxDialog({super.key});

  @override
  State<SyncOutboxDialog> createState() => _SyncOutboxDialogState();
}

class _SyncOutboxDialogState extends State<SyncOutboxDialog> {
  bool _isSyncing = false;
  String? _syncStatusMessage;

  Future<void> _handleManualSync() async {
    setState(() {
      _isSyncing = true;
      _syncStatusMessage = null;
    });

    try {
      final apiClient = context.read<ApiClient>();
      final syncService = PosSyncService(apiClient: apiClient);
      final count = await syncService.syncPendingOrders();

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatusMessage = count > 0
              ? 'Успешно синхронизировано чеков: $count'
              : 'Нет чеков для синхронизации';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatusMessage = 'Ошибка синхронизации: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orders = PosOutboxService.getPendingOrders();
    final totalAmount = PosOutboxService.pendingTotalAmount;

    return AppCardDialog(
      title: 'Офлайн-чеки & Локальная сеть',
      subtitle: 'Очередь заказов, ожидающих выгрузки на сервер',
      icon: PhosphorIconsRegular.cloudArrowUp,
      width: 580,
      actions: [
        AppGhostButton(
          label: 'Отмена',
          onPressed: () => Navigator.pop(context),
        ),
        AppPrimaryButton(
          label: _isSyncing ? 'Синхронизация...' : 'Синхронизировать',
          icon: PhosphorIconsRegular.arrowsClockwise,
          isLoading: _isSyncing,
          onPressed: _handleManualSync,
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Сводные KPI карточки ──
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: AppRadii.radiusLg,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('В памяти кассы', style: AppTextStyles.caption),
                      const SizedBox(height: 4),
                      Text('${orders.length} чеков', style: AppTextStyles.h3),
                      Text(
                        'на сумму ${totalAmount.toStringAsFixed(0)} сом',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: AppRadii.radiusLg,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Синхронизация', style: AppTextStyles.caption),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: orders.isEmpty ? AppColors.success : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            orders.isEmpty ? 'Все чеки в облаке' : 'Ожидают отправки',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        orders.isEmpty ? 'Касса синхронизирована' : 'Автоотправка при сети',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_syncStatusMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: AppRadii.radiusMd,
              ),
              child: Text(
                _syncStatusMessage!,
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Список неотправленных чеков ──
          Text(
            'Список неотправленных заказов:',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: orders.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: AppEmptyState(
                      icon: PhosphorIconsRegular.checkCircle,
                      title: 'Все чеки отправлены на сервер',
                      description: 'Очередь чиста, данные актуальны',
                      customColor: AppColors.success,
                      size: AppEmptyStateSize.sm,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => SyncOutboxOrderCard(order: orders[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
