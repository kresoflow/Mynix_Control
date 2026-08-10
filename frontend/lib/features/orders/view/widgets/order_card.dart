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
              child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildOrderNumberBadge(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(widget.order.createdAt),
                style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext),
              ),
              const SizedBox(height: 4),
              Text('${widget.order.items.length} позиций', style: AppTextStyles.body),
            ],
          ),
        ),
        _buildStatusBadge(widget.order.status),
        const SizedBox(width: 24),
        Text(widget.order.total.toCurrency(context), style: AppTextStyles.h3),
        const SizedBox(width: 16),
        Icon(PhosphorIconsRegular.caretRight, color: AppColors.darkSubtext),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildOrderNumberBadge(),
            _buildStatusBadge(widget.order.status),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(widget.order.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.darkSubtext),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.order.items.length} позиций',
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
            Text(
              widget.order.total.toCurrency(context),
              style: AppTextStyles.h2.copyWith(color: AppColors.brandPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderNumberBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '#${widget.order.orderNumber}',
        style: AppTextStyles.body.copyWith(
          color: AppColors.brandPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'new':
        color = AppColors.brandPrimary;
        label = 'Новый';
        break;
      case 'cooking':
        color = AppColors.warning;
        label = 'Готовится';
        break;
      case 'ready':
        color = AppColors.success;
        label = 'Готов';
        break;
      case 'completed':
        color = AppColors.darkSubtext;
        label = 'Завершен';
        break;
      case 'cancelled':
        color = AppColors.danger;
        label = 'Отменен';
        break;
      default:
        color = AppColors.darkText;
        label = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
