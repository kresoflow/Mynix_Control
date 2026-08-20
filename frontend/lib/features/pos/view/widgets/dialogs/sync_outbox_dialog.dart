import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import '../../../services/pos_outbox_service.dart';
import '../../../services/pos_sync_service.dart';
import '../../../services/lan/local_pos_server.dart';
import 'sync_outbox_order_card.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final orders = PosOutboxService.getPendingOrders();
    final totalAmount = PosOutboxService.pendingTotalAmount;
    final isLanRunning = LocalPosServer.isRunning;
    final lanIp = LocalPosServer.localIpAddress ?? '127.0.0.1';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 16 : 24),
      child: Container(
        width: isMobile ? screenWidth - 24 : 600,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.cloudArrowUp,
                    color: AppColors.brandPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Офлайн-чеки & Локальная сеть', style: AppTextStyles.h3),
                      Text(
                        'Очередь заказов, ожидающих выгрузки на сервер',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
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
                        Text('на сумму ${totalAmount.toStringAsFixed(0)} сом', style: AppTextStyles.caption.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
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
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Локальная сеть (Wi-Fi Hub)', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLanRunning ? AppColors.success : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(isLanRunning ? 'Активен' : 'Остановлен', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('IP: $lanIp:${LocalPosServer.port}', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_syncStatusMessage!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
            ],

            // Orders list
            Text('Список неотправленных заказов:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsRegular.checkCircle, size: 48, color: AppColors.success),
                          const SizedBox(height: 10),
                          Text('Все чеки отправлены на сервер', style: AppTextStyles.body),
                          Text('Очередь чиста, данные актуальны', style: AppTextStyles.caption),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => SyncOutboxOrderCard(order: orders[index]),
                    ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Закрыть',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: isMobile ? 1 : 2,
                  child: AppButton.primary(
                    label: _isSyncing
                        ? 'Синхронизация...'
                        : (isMobile ? 'Выгрузить' : 'Синхронизировать сейчас'),
                    icon: PhosphorIconsRegular.arrowsClockwise,
                    isLoading: _isSyncing,
                    onPressed: _handleManualSync,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
