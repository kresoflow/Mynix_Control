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
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
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
              child: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return _buildUnifiedLayout(isDark);
  }

  Widget _buildMobileLayout(bool isDark) {
    return _buildUnifiedLayout(isDark);
  }

  Widget _buildUnifiedLayout(bool isDark) {
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancelled ? PhosphorIconsRegular.xCircle : PhosphorIconsRegular.receipt,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заказ #${widget.order.orderNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCancelled ? 0.0 : widget.order.total.toCurrency(context)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCancelled ? subtextColor : textColor,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
        const SizedBox(height: 12),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.order.items.map((e) => '${e.quantity}x ${e.menuItemName}').join(', '),
                style: TextStyle(
                  fontSize: 13,
                  color: subtextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(PhosphorIconsRegular.caretRight, color: subtextColor, size: 20),
          ],
        ),
      ],
    );
  }

}
