// ==============================================================================
// МОДУЛЬ: POS / Разделение счета (SplitBillDialog)
// ДОМЕН: lib/features/pos/view/widgets/tables/split_bill_dialog.dart
// ==============================================================================
//
// [ИНВАРИАНТ] [UI-KIT] Диалог разделения позиций заказа по гостям:
// 1. Позволяет интерактивно перемещать блюда между чеками Гостя 1 и Гостя 2.
// 2. Рассчитывает подытоги чеков раздельно и позволяет закрывать их независимо.
// 3. Использует дизайн-токены AppRadii, AppColors, AppSpacing и кнопки AppButton.
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
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'package:kreso_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:kreso_frontend/features/pos/bloc/shift_event.dart';
import 'package:kreso_frontend/features/pos/repository/order_repository.dart';
import 'split_bill_guest_column.dart';
import 'table_order_payment_modal.dart';

// ── 1. Диалог разделения счета ────────────────────────────────────────────────

class SplitBillDialog extends StatefulWidget {
  final Map<String, dynamic> tableData;
  final VoidCallback onUpdated;

  const SplitBillDialog({
    super.key,
    required this.tableData,
    required this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> tableData,
    required VoidCallback onUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SplitBillDialog(tableData: tableData, onUpdated: onUpdated),
    );
  }

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  final OrderRepository _orderRepo = OrderRepository(apiClient.dio);
  late List<Map<String, dynamic>> _guest1Items;
  final List<Map<String, dynamic>> _guest2Items = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final raw = (widget.tableData['clean_items'] as List?) ?? (widget.tableData['items'] as List?) ?? [];
    _guest1Items = raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  double _calcTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, it) {
      final unitPrice = (it['unit_price'] as num?)?.toDouble() ?? 0.0;
      final qty = it['quantity'] as int? ?? 1;
      return sum + (unitPrice * qty);
    });
  }

  void _moveItem(Map<String, dynamic> item, List<Map<String, dynamic>> from, List<Map<String, dynamic>> to) {
    setState(() {
      final qty = item['quantity'] as int? ?? 1;
      if (qty > 1) {
        item['quantity'] = qty - 1;
        final existing = to.where((x) => x['menu_item_id'] == item['menu_item_id']).firstOrNull;
        if (existing != null) {
          existing['quantity'] = (existing['quantity'] as int) + 1;
        } else {
          final copy = Map<String, dynamic>.from(item);
          copy['quantity'] = 1;
          to.add(copy);
        }
      } else {
        from.remove(item);
        final existing = to.where((x) => x['menu_item_id'] == item['menu_item_id']).firstOrNull;
        if (existing != null) {
          existing['quantity'] = (existing['quantity'] as int) + 1;
        } else {
          to.add(item);
        }
      }
    });
  }

  Future<void> _payGuestBill(int guestIndex, List<Map<String, dynamic>> items) async {
    if (items.isEmpty || _isProcessing) return;
    final orderId = widget.tableData['order_id'] as int? ?? widget.tableData['id'] as int;
    final guestTotal = _calcTotal(items);

    final mockOrderPayload = {
      'order_id': orderId,
      'order_number': widget.tableData['order_number'],
      'table_number': widget.tableData['table_number'],
      'total': guestTotal,
      'items': items,
    };

    await TableOrderPaymentModal.show(
      context,
      order: mockOrderPayload,
      onConfirm: (paymentMethod) async {
        setState(() => _isProcessing = true);
        try {
          await _orderRepo.splitOrder(orderId, items, paymentMethod);
          if (mounted) {
            AppToast.showSuccess(context, 'Чек гостя $guestIndex оплачен');
            final now = DateTime.now();
            final start = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc().toIso8601String();
            final end = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();
            context.read<OrdersBloc>().add(LoadOrders(startDate: start, endDate: end));
            context.read<ShiftBloc>().add(const CheckCurrentShift());

            setState(() {
              _isProcessing = false;
              if (guestIndex == 1) {
                _guest1Items.clear();
              } else {
                _guest2Items.clear();
              }
            });

            widget.onUpdated();
            if (_guest1Items.isEmpty && _guest2Items.isEmpty) {
              Navigator.pop(context);
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isProcessing = false);
            AppToast.showError(context, 'Ошибка оплаты', subtitle: e.toString());
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final tableNumber = widget.tableData['table_number']?.toString() ?? 'Стол';
    final total1 = _calcTotal(_guest1Items);
    final total2 = _calcTotal(_guest2Items);

    return Dialog(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.dialogRadius),
      child: Container(
        width: 820,
        height: 620,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Шапка диалога ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsBold.scissors, color: AppColors.brandPrimary, size: 20),
                ),
                AppSpacing.hSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Разделение счета — $tableNumber', style: AppTextStyles.h3),
                      Text(
                        'Нажмите на стрелку у позиции, чтобы перенести ее в другой чек',
                        style: TextStyle(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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

            // ── Колонки: Гость 1 и Гость 2 ──────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: PosSplitBillGuestColumn(
                      index: 1,
                      items: _guest1Items,
                      total: total1,
                      border: border,
                      isDark: isDark,
                      isProcessing: _isProcessing,
                      onMove: (it) => _moveItem(it, _guest1Items, _guest2Items),
                      onPay: () => _payGuestBill(1, _guest1Items),
                      isLeft: true,
                    ),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: PosSplitBillGuestColumn(
                      index: 2,
                      items: _guest2Items,
                      total: total2,
                      border: border,
                      isDark: isDark,
                      isProcessing: _isProcessing,
                      onMove: (it) => _moveItem(it, _guest2Items, _guest1Items),
                      onPay: () => _payGuestBill(2, _guest2Items),
                      isLeft: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
