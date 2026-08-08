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
          width: 420,
          constraints: const BoxConstraints(maxHeight: 800),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F222A) : const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(PhosphorIconsFill.receipt, color: AppColors.brandPrimary, size: 28),
                        ),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.x),
                          onPressed: () => Navigator.pop(context),
                          color: subtext,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Чек #${order.orderNumber}',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.total.toCurrency(context),
                      style: AppTextStyles.h1.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Dashed separator (Visual)
              SizedBox(
                height: 1,
                child: CustomPaint(painter: _DashedLinePainter(color: isDark ? Colors.white24 : Colors.black12)),
              ),

              // Receipt Meta
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _MetaRow('Время', DateFormat('HH:mm  dd.MM.yyyy').format(order.createdAt), text, subtext),
                    const SizedBox(height: 12),
                    _MetaRow('Способ оплаты', order.paymentMethod == 'cash' ? 'Наличные' : 'Банковская карта', text, subtext),
                    const SizedBox(height: 12),
                    _MetaRow('Статус', _localizeStatus(order.status), _getStatusColor(order.status), subtext),
                  ],
                ),
              ),

              SizedBox(
                height: 1,
                child: CustomPaint(painter: _DashedLinePainter(color: isDark ? Colors.white24 : Colors.black12)),
              ),

              // Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.menuItemName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('С модификаторами', style: AppTextStyles.caption.copyWith(color: subtext)),
                              ],
                              const SizedBox(height: 4),
                              Text('${item.quantity}  x  ${item.unitPrice.toCurrency(context)}', style: AppTextStyles.caption.copyWith(color: subtext)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(item.subtotal.toCurrency(context), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    );
                  },
                ),
              ),

              if (canCancel)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AppDangerButton(
                      label: 'Отменить этот чек',
                      onPressed: () {
                        context.read<OrdersBloc>().add(CancelOrder(order.id));
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _MetaRow(String label, String value, Color valueColor, Color labelColor) {
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
      case 'new': return AppColors.brandPrimary;
      case 'cooking': return AppColors.warning;
      case 'ready': return AppColors.success;
      case 'completed': return AppColors.darkSubtext;
      case 'cancelled': return AppColors.danger;
      default: return AppColors.darkText;
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 5, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
