// ==============================================================================
// МОДУЛЬ: POS / Табло активных столиков (PosActiveTablesDialog)
// ДОМЕН: lib/features/pos/view/widgets/tables/pos_active_tables_dialog.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Диалоговое окно мониторинга всех активных столиков зала:
// 1. Отображает сводную информацию: количество открытых столов и общую сумму.
// 2. Рендерит адаптивную сетку карточек PosActiveTableCard.
// 3. Поддерживает быстрый дозаказ, расчет, подачу в зал и отмену заказа со столика.
//
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/network/api_client.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_spacing.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/app_empty_state.dart';
import 'package:kreso_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:kreso_frontend/features/orders/models/pos_order.dart';
import 'package:kreso_frontend/features/orders/view/widgets/cancel_order_dialog.dart';
import 'package:kreso_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/pos_tab_cubit.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';
import 'pos_active_table_card.dart';
import 'split_bill_dialog.dart';
import 'table_order_payment_modal.dart';

// ── 1. Табло активных столиков ────────────────────────────────────────────────

class PosActiveTablesDialog extends StatefulWidget {
  const PosActiveTablesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PosActiveTablesDialog(),
    );
  }

  @override
  State<PosActiveTablesDialog> createState() => _PosActiveTablesDialogState();
}

class _PosActiveTablesDialogState extends State<PosActiveTablesDialog> {
  final OrderRepository _orderRepo = OrderRepository(apiClient.dio);
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveTables();
  }

  Future<void> _loadActiveTables({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final tables = await _orderRepo.fetchActiveTables();
      if (mounted) {
        setState(() {
          _tables = tables;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Ошибка загрузки столиков', subtitle: e.toString());
      }
    }
  }

  void _handleDozakaz(Map<String, dynamic> table) {
    final tableNumber = table['table_number']?.toString();
    if (tableNumber != null) {
      context.read<CartBloc>().add(SetTableNumber(tableNumber));
      Navigator.pop(context);
      AppToast.showInfo(
        context,
        'Выбран $tableNumber для дозаказа',
        subtitle: 'Выберите блюда в меню слева и нажмите «Оформить»',
      );
    }
  }

  Future<void> _handleSettle(Map<String, dynamic> table) async {
    final orderId = table['order_id'] as int? ?? table['id'] as int;
    await TableOrderPaymentModal.show(
      context,
      order: table,
      onConfirm: (paymentMethod) async {
        try {
          await _orderRepo.settleTableOrder(orderId, paymentMethod);
          if (mounted) {
            AppToast.showSuccess(context, 'Столик рассчитан и закрыт');
            final now = DateTime.now();
            final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc().toIso8601String();
            final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();
            context.read<OrdersBloc>().add(LoadOrders(startDate: startOfToday, endDate: endOfToday));
            context.read<ShiftBloc>().add(const CheckCurrentShift());
            context.read<PosTabCubit>().refreshCounts();
            _loadActiveTables(silent: true);
          }
        } catch (e) {
          if (mounted) AppToast.showError(context, 'Ошибка расчета', subtitle: e.toString());
        }
      },
    );
  }

  Future<void> _handleCancel(Map<String, dynamic> table) async {
    final orderId = table['order_id'] as int? ?? table['id'] as int;
    final orderNumber = table['order_number'] as int? ?? orderId;
    final tableNum = table['table_number']?.toString() ?? 'Стол';

    final order = PosOrder(
      id: orderId,
      orderNumber: orderNumber,
      status: 'pending',
      paymentMethod: 'cash',
      total: (table['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.now(),
      items: const [],
    );

    final reason = await CancelOrderDialog.show(context, order: order);
    if (reason != null && mounted) {
      try {
        await _orderRepo.cancelOrder(orderId);
        if (mounted) {
          AppToast.showSuccess(context, 'Заказ на $tableNum отменен');
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc().toIso8601String();
          final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();
          context.read<OrdersBloc>().add(LoadOrders(startDate: startOfToday, endDate: endOfToday));
          context.read<ShiftBloc>().add(const CheckCurrentShift());
          context.read<PosTabCubit>().refreshCounts();
          _loadActiveTables(silent: true);
        }
      } catch (e) {
        if (mounted) AppToast.showError(context, 'Ошибка отмены', subtitle: e.toString());
      }
    }
  }

  Future<void> _handleMarkServed(Map<String, dynamic> table) async {
    final orderId = table['order_id'] as int? ?? table['id'] as int;
    final tableNum = table['table_number']?.toString() ?? 'Стол';
    try {
      await _orderRepo.markOrderServed(orderId);
      if (mounted) {
        AppToast.showSuccess(context, 'Заказ подан на $tableNum');
        _loadActiveTables(silent: true);
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Ошибка', subtitle: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final totalHallSum = _tables.fold<double>(0.0, (acc, t) => acc + ((t['total'] as num?)?.toDouble() ?? 0.0));

    return Dialog(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      child: Container(
        width: 860,
        height: 640,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Шапка табло ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsBold.chair, color: AppColors.brandPrimary, size: 22),
                ),
                AppSpacing.hSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Активные столики зала', style: AppTextStyles.h3),
                          AppSpacing.hSm,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.15),
                              borderRadius: AppRadii.radiusMd,
                            ),
                            child: Text(
                              '${_tables.length} открыто',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'В зале на сумму: ${totalHallSum.toCurrency(context)}',
                        style: TextStyle(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadActiveTables,
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 20),
                  tooltip: 'Обновить',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(PhosphorIconsRegular.x, size: 20),
                ),
              ],
            ),
            AppSpacing.vSm,
            Divider(color: border, height: 1),
            AppSpacing.vSm,

            // ── Контент ─────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tables.isEmpty
                      ? const Center(
                          child: AppEmptyState(
                            icon: PhosphorIconsRegular.chair,
                            title: 'Все столики свободны',
                            description: 'Нет открытых счетов и заказов в зале',
                            size: AppEmptyStateSize.lg,
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: _tables.length,
                          itemBuilder: (context, index) {
                            final table = _tables[index];
                            return PosActiveTableCard(
                              tableData: table,
                              onDozakaz: () => _handleDozakaz(table),
                              onSplit: () => SplitBillDialog.show(
                                context,
                                tableData: table,
                                onUpdated: () => _loadActiveTables(silent: true),
                              ),
                              onSettle: () => _handleSettle(table),
                              onMarkServed: () => _handleMarkServed(table),
                              onCancel: () => _handleCancel(table),
                              isDark: isDark,
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
