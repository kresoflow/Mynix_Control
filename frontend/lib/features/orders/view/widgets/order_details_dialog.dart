import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/pos_order.dart';
import '../../bloc/orders_bloc.dart';

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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Center(
        child: Container(
          width: 440,
          constraints: const BoxConstraints(maxHeight: 800),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header (Order Number & Status Badge) ─────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                            Text(
                              'Чек #${order.orderNumber}',
                              style: AppTextStyles.h2,
                            ),
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

              // Dashed separator
              SizedBox(
                height: 1,
                child: CustomPaint(painter: _DashedLinePainter(color: isDark ? Colors.white24 : Colors.black12)),
              ),

              // ── Receipt Meta ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _buildMetaRow('Способ оплаты', order.paymentMethod == 'cash' ? 'Наличные' : 'Банковская карта / Перевод', text, subtext),
                    const SizedBox(height: 10),
                    _buildMetaRow('Статус чека', _localizeStatus(order.status), _getStatusColor(order.status), subtext),
                  ],
                ),
              ),

              SizedBox(
                height: 1,
                child: CustomPaint(painter: _DashedLinePainter(color: isDark ? Colors.white24 : Colors.black12)),
              ),

              // ── Items List ───────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: order.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.menuItemName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'С модификаторами',
                            style: AppTextStyles.caption.copyWith(color: subtext, fontSize: 11),
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

              // ── Bottom Summary & Total (UX Fixed: prominently placed at bottom of receipt) ──
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
                          icon: PhosphorIconsRegular.checkCircle,
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
                          onPressed: () {
                            context.read<OrdersBloc>().add(CancelOrder(order.id));
                            Navigator.pop(context);
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

  Widget _buildMetaRow(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: labelColor)),
        Text(value, style: AppTextStyles.body.copyWith(color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _localizeStatus(String status) {
    switch (status) {
      case 'new': return 'Новый';
      case 'cooking': return 'Готовится';
      case 'ready': return 'Готов к выдаче';
      case 'completed': return 'Завершен';
      case 'cancelled': return 'Отменен';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.danger;
      case 'new':
      case 'cooking':
      case 'ready':
      default: return AppColors.warning;
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
