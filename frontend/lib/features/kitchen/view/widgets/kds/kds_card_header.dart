import 'package:flutter/material.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class KdsCardHeader extends StatelessWidget {
  final dynamic orderNumber;
  final dynamic orderId;
  final String status;
  final Color statusColor;
  final bool isDark;

  const KdsCardHeader({
    super.key,
    required this.orderNumber,
    required this.orderId,
    required this.status,
    required this.statusColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '#${orderNumber ?? orderId}',
            style: AppTextStyles.h1.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              status.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
