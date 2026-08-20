import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import '../../../models/offline_order_payload.dart';

class SyncOutboxOrderCard extends StatelessWidget {
  final OfflineOrderPayload order;

  const SyncOutboxOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm:ss').format(order.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${order.orderNumber}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Чек #${order.orderNumber} • ${order.items.length} поз.',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$timeStr • Оплата: ${order.paymentMethod.toUpperCase()}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '${order.totalAmount.toStringAsFixed(0)} сом',
            style: AppTextStyles.h3.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
