import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/widgets/app_toast.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/features/pos/repository/order_repository.dart';
import 'incoming_order_card.dart';

class IncomingOrdersDialog extends StatefulWidget {
  const IncomingOrdersDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const IncomingOrdersDialog(),
    );
  }

  @override
  State<IncomingOrdersDialog> createState() => _IncomingOrdersDialogState();
}

class _IncomingOrdersDialogState extends State<IncomingOrdersDialog> {
  final OrderRepository _orderRepo = OrderRepository(apiClient.dio);
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  Future<void> _loadPendingOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderRepo.fetchPendingOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Ошибка загрузки', subtitle: e.toString());
      }
    }
  }

  Future<void> _approveOrder(int orderId) async {
    try {
      await _orderRepo.approveOrder(orderId);
      if (mounted) {
        AppToast.showSuccess(context, 'Заказ отправлен на кухню');
        _loadPendingOrders();
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Ошибка', subtitle: e.toString());
    }
  }

  Future<void> _payAndApproveOrder(Map<String, dynamic> order) async {
    final orderId = order['id'] as int;
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;

    String selectedMethod = 'cash';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Оплата заказа #${order['order_number']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Сумма к оплате: $total сом', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('Наличные'),
                value: 'cash',
                groupValue: selectedMethod,
                onChanged: (val) => setDialogState(() => selectedMethod = val!),
              ),
              RadioListTile<String>(
                title: const Text('Карта / Терминал'),
                value: 'card',
                groupValue: selectedMethod,
                onChanged: (val) => setDialogState(() => selectedMethod = val!),
              ),
              RadioListTile<String>(
                title: const Text('Перевод (Mbank / Optima)'),
                value: 'transfer',
                groupValue: selectedMethod,
                onChanged: (val) => setDialogState(() => selectedMethod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _orderRepo.approveOrder(orderId, paymentMethod: selectedMethod, isPaid: true);
                  if (mounted) {
                    AppToast.showSuccess(context, 'Оплачено и отправлено в цех');
                    _loadPendingOrders();
                  }
                } catch (e) {
                  if (mounted) AppToast.showError(context, 'Ошибка', subtitle: e.toString());
                }
              },
              child: const Text('Подтвердить оплату'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectOrder(int orderId) async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отклонить заказ?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Причина (например: блюдо закончилось)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Назад')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _orderRepo.rejectOrder(orderId, reason: reasonController.text);
                if (mounted) {
                  AppToast.showWarning(context, 'Заказ отклонен');
                  _loadPendingOrders();
                }
              } catch (e) {
                if (mounted) AppToast.showError(context, 'Ошибка', subtitle: e.toString());
              }
            },
            child: const Text('Отклонить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsBold.bellRinging, color: AppColors.brandPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Входящие заказы с зала',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      Text(
                        'Ожидают подтверждения кассира (${_orders.length})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadPendingOrders,
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                  tooltip: 'Обновить',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(PhosphorIconsRegular.x),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsRegular.checkCircle, size: 48, color: Colors.green.withValues(alpha: 0.6)),
                              const SizedBox(height: 12),
                              const Text(
                                'Нет новых входящих заказов',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Заказы от официантов появятся здесь',
                                style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final orderId = order['id'] as int;
                            return IncomingOrderCard(
                              order: order,
                              onApprove: () => _approveOrder(orderId),
                              onPayAndApprove: () => _payAndApproveOrder(order),
                              onReject: () => _rejectOrder(orderId),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
