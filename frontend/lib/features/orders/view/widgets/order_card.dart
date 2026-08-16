import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/utils/currency_formatter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/features/orders/models/pos_order.dart';
import 'package:mynix_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:mynix_frontend/features/orders/view/widgets/order_details_dialog.dart';

class OrderCard extends StatefulWidget {
  final PosOrder order;
  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? AppColors.brandPrimary.withValues(alpha: 0.5) : border,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => BlocProvider.value(
                  value: context.read<OrdersBloc>(),
                  child: OrderDetailsDialog(order: widget.order),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildLayout(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(bool isDark) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    
    final isCancelled = widget.order.status == 'cancelled';
    Color statusColor;
    String statusText;

    switch (widget.order.status) {
      case 'completed':
        statusColor = AppColors.success;
        statusText = 'Завершен';
        break;
      case 'cancelled':
        statusColor = AppColors.danger;
        statusText = 'Отменен';
        break;
      case 'new':
      case 'cooking':
      case 'ready':
      default:
        statusColor = AppColors.warning;
        statusText = 'В процессе';
        break;
    }

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(widget.order.createdAt);
    final totalItemsCount = widget.order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TOP HEADER: Order Number, Date & Status Badge ─────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCancelled ? PhosphorIconsRegular.xCircle : PhosphorIconsRegular.receipt,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ #${widget.order.orderNumber}',
                      style: AppTextStyles.h3.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: AppTextStyles.caption.copyWith(color: subtextColor),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                statusText,
                style: AppTextStyles.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        
        // ── MIDDLE: Items preview ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.order.items.map((e) => '${e.quantity}x ${e.menuItemName}').join(', '),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
        const SizedBox(height: 10),
        
        // ── BOTTOM TOTAL BAR (UX Fixed: Clear financial bottom-line) ─
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  widget.order.paymentMethod == 'cash' 
                      ? PhosphorIconsRegular.money 
                      : PhosphorIconsRegular.creditCard,
                  size: 16,
                  color: subtextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.order.paymentMethod == 'cash' ? 'Наличные' : 'Безналичный',
                  style: AppTextStyles.caption.copyWith(color: subtextColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: subtextColor, fontSize: 12)),
                const SizedBox(width: 8),
                Text(
                  '$totalItemsCount шт.',
                  style: AppTextStyles.caption.copyWith(color: subtextColor),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Итого: ',
                  style: AppTextStyles.caption.copyWith(color: subtextColor),
                ),
                Text(
                  isCancelled ? '0.00' : widget.order.total.toCurrency(context),
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCancelled ? subtextColor : (isDark ? AppColors.darkText : AppColors.lightText),
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(PhosphorIconsRegular.caretRight, color: subtextColor, size: 16),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
