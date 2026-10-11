import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';
import 'package:kreso_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:kreso_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'incoming_order_card.dart';
import 'incoming_order_payment_modal.dart';
import 'incoming_order_reject_modal.dart';

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

  void _notifyStateUpdates() {
    if (!mounted) return;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc().toIso8601String();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();
    context.read<OrdersBloc>().add(LoadOrders(startDate: startOfToday, endDate: endOfToday));
    context.read<ShiftBloc>().add(CheckCurrentShift());
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

  Future<void> _approveOrder(int orderId, bool useKds) async {
    try {
      await _orderRepo.approveOrder(orderId);
      if (mounted) {
        AppToast.showSuccess(
          context,
          useKds ? 'Заказ отправлен на кухню' : 'Заказ принят',
        );
        _notifyStateUpdates();
        _loadPendingOrders();
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Ошибка', subtitle: e.toString());
    }
  }

  Future<void> _payAndApproveOrder(Map<String, dynamic> order) async {
    final orderId = order['id'] as int;
    await IncomingOrderPaymentModal.show(
      context,
      order: order,
      onConfirm: (paymentMethod) async {
        try {
          await _orderRepo.approveOrder(orderId, paymentMethod: paymentMethod, isPaid: true);
          if (mounted) {
            AppToast.showSuccess(context, 'Заказ оплачен и подтвержден');
            _notifyStateUpdates();
            _loadPendingOrders();
          }
        } catch (e) {
          if (mounted) AppToast.showError(context, 'Ошибка', subtitle: e.toString());
        }
      },
    );
  }

  Future<void> _rejectOrder(Map<String, dynamic> order) async {
    final orderId = order['id'] as int;
    final orderNum = (order['order_number'] as num?)?.toInt() ?? orderId;
    await IncomingOrderRejectModal.show(
      context,
      orderNumber: orderNum,
      onConfirm: (reason) async {
        try {
          await _orderRepo.rejectOrder(orderId, reason: reason);
          if (mounted) {
            AppToast.showWarning(context, 'Заказ отклонен');
            _notifyStateUpdates();
            _loadPendingOrders();
          }
        } catch (e) {
          if (mounted) AppToast.showError(context, 'Ошибка', subtitle: e.toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useKds = context.watch<SettingsBloc>().state.useKds;

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
                  child: Icon(
                    PhosphorIconsBold.bellRinging,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
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
                              Icon(
                                PhosphorIconsRegular.bellSlash,
                                size: 48,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Нет новых входящих заказов',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Заказы со столиков появятся здесь',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                  fontSize: 13,
                                ),
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
                              useKds: useKds,
                              isReadOnly: false,
                              onApprove: () => _approveOrder(orderId, useKds),
                              onPayAndApprove: () => _payAndApproveOrder(order),
                              onReject: () => _rejectOrder(order),
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
