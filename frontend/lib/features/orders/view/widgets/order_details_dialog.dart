// ==============================================================================
// Title: OrderDetailsDialog (order_details_dialog.dart)
// Path: frontend/lib/features/orders/view/widgets/order_details_dialog.dart
// Description: Модальное окно детализации кассового чека / заказа.
// ==============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_radii.dart';
import 'package:kreso_frontend/core/theme/app_shadows.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/utils/currency_formatter.dart';
import 'package:kreso_frontend/core/widgets/app_button.dart';
import 'package:kreso_frontend/core/widgets/app_save_shortcut_scope.dart';
import '../../models/pos_order.dart';
import '../../bloc/orders_bloc.dart';
import 'cancel_order_dialog.dart';

// ─── 1. Модальное окно чека ──────────────────────────────────────────────────

/// [UI-KIT] Диалог детальной информации по чеку/заказу.
/// Адаптируется по высоте содержимого (wrap-content) и поддерживает Esc / закрытие по клику вне окна.
class OrderDetailsDialog extends StatelessWidget {
  final PosOrder order;

  const OrderDetailsDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final canCancel = order.status != 'cancelled' && order.status != 'completed';
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AppSaveShortcutScope(
      onCancel: () => Navigator.of(context).maybePop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: min(440.0, screenWidth - 32.0),
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.dialogRadius,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: AppShadows.dialog,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Шапка (Номер чека, дата и закрытие) ────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.dialog)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(PhosphorIconsFill.receipt, color: AppColors.brandPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Чек #${order.orderNumber}', style: AppTextStyles.h2),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd.MM.yyyy, HH:mm').format(order.createdAt),
                              style: AppTextStyles.caption.copyWith(color: subtext),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.x),
                      onPressed: () => Navigator.pop(context),
                      color: subtext,
                    ),
                  ],
                ),
              ),

              // Пунктирный разделитель
              SizedBox(
                height: 1,
                child: CustomPaint(painter: _DashedLinePainter(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),

              // ── Метаданные чека (Способ оплаты, статус) ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _buildMetaRow('Способ оплаты', order.paymentMethodLabel, text, subtext),
                    const SizedBox(height: 10),
                    _buildMetaRow('Статус чека', _localizeStatus(order.status), _getStatusColor(order.status), subtext),
                  ],
                ),
              ),

              SizedBox(
                height: 1,
                child: CustomPaint(painter: _DashedLinePainter(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),

              // ── Список позиций чека (Адаптивная высота) ───────────────────
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.cleanName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        if (item.optionsSummary != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.optionsSummary!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity} × ${item.unitPrice.toCurrency(context)}',
                              style: AppTextStyles.caption.copyWith(
                                color: subtext,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              item.subtotal.toCurrency(context),
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Итоговый блок чека ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightBg,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ИТОГО К ОПЛАТЕ:',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        Text(
                          order.total.toCurrency(context),
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (canCancel) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: AppPrimaryButton(
                          label: 'Выдать заказ (Завершить)',
                          onPressed: () {
                            context.read<OrdersBloc>().add(CompleteOrder(order.id));
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: AppDangerButton(
                          label: 'Отменить этот чек',
                          icon: PhosphorIconsRegular.xCircle,
                          onPressed: () async {
                            final reason = await CancelOrderDialog.show(context, order: order);
                            if (reason != null && context.mounted) {
                              context.read<OrdersBloc>().add(CancelOrder(order.id));
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Color valueColor, Color labelColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: labelColor)),
          Text(value, style: AppTextStyles.body.copyWith(color: valueColor, fontWeight: FontWeight.w600)),
        ],
      );

  String _localizeStatus(String status) => switch (status) {
        'new' => 'Новый',
        'cooking' => 'Готовится',
        'ready' => 'Готов к выдаче',
        'completed' => 'Завершен',
        'cancelled' => 'Отменен',
        _ => status,
      };

  Color _getStatusColor(String status) => switch (status) {
        'completed' => AppColors.success,
        'cancelled' => AppColors.danger,
        _ => AppColors.warning,
      };
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
